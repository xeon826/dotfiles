pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 * - Resolves window icons to file:// URLs (see windowIconSource)
 */
Singleton {
    id: root
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2

    /**
     * Bumped ~once a second for the first 8s after each engine (re)load.
     * DesktopEntries.byId() is a non-reactive Q_INVOKABLE and returns null
     * until the entries scan finishes, so icon bindings read this property to
     * re-evaluate once guesses improve (e.g. "org.mozilla.Thunderbird" →
     * "thunderbird" via the entry's icon key).
     */
    property int entriesGeneration: 0
    Timer {
        running: root.entriesGeneration < 8
        interval: 1000
        repeat: true
        onTriggered: root.entriesGeneration++
    }

    // --- Window icon resolution (QIcon-free) ---
    // On this quickshell build (0.3.2.r11.g9b0f339 + Qt 6.12.0-3), QIcon::
    // fromTheme goes per-name flaky after the first engine reload — the first
    // engine of a fresh process resolves fine, later engines miss common
    // hicolor icons (kitty, application-x-executable, even image-missing).
    // Therefore window icons NEVER go through QIcon: we locate the icon file
    // on disk (cached per name) and serve it as a file:// URL, which
    // Quickshell's IconImage (a plain Image alias) renders directly.
    property var _resolvedIconFiles: ({}) // icon name -> absolute file path
    property var _findQueue: []

    function windowIconSource(windowClass) {
        const generation = AppSearch.entriesGeneration; // re-run while entries settle
        const guessed = AppSearch.guessIcon(windowClass);
        if (guessed === "image-missing") return "";
        const file = root._resolvedIconFiles[guessed];
        if (file === undefined) root.resolveIconFile(guessed);
        return file ? "file://" + file : "";
    }

    function resolveIconFile(name) {
        const safe = name.replace(/[^a-zA-Z0-9._-]/g, "");
        if (!safe || root._resolvedIconFiles[safe] !== undefined || root._findQueue.includes(safe)) return;
        root._findQueue = [...root._findQueue, safe];
        root.drainFindQueue();
    }

    function drainFindQueue() {
        if (findProc.running || root._findQueue.length === 0) return;
        const name = root._findQueue[0];
        findProc.name = name;
        findProc.command = ["bash", "-c",
            `find "$HOME/.local/share/icons/hicolor" /usr/share/icons/hicolor /usr/share/icons/Adwaita /usr/share/pixmaps -maxdepth 4 \\( -name '${name}.svg' -o -name '${name}.svgz' -o -name '${name}.png' -o -name '${name}.xpm' \\) -print 2>/dev/null`];
        findProc.running = true;
    }

    function _pickIconFile(output) {
        const files = output.trim().split("\n").filter(f => f.length > 0);
        if (files.length === 0) return "";
        const svg = files.find(f => f.endsWith(".svg") || f.endsWith(".svgz")); // scales best
        if (svg) return svg;
        return files.reduce((best, f) => { // prefer the largest size directory
            const sizeOf = p => (p.match(/\/(\d+)x\1\//) ?? [])[1] ?? "0";
            return (parseInt(sizeOf(f)) > parseInt(sizeOf(best))) ? f : best;
        }, files[0]);
    }

    Process {
        id: findProc
        property string name: ""
        command: []
        stdout: StdioCollector {
            id: findCollector
            onStreamFinished: {
                const map = {};
                for (const k in root._resolvedIconFiles) map[k] = root._resolvedIconFiles[k];
                map[findProc.name] = root._pickIconFile(findCollector.text);
                root._resolvedIconFiles = map;
                root._findQueue = root._findQueue.filter(n => n !== findProc.name);
                root.drainFindQueue();
            }
        }
    }
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    // Deduped list to fix double icons
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .filter((app, index, self) => 
            index === self.findIndex((t) => (
                t.id === app.id
            ))
    )
    
    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    readonly property var preppedIcons: list.map(a => ({
        name: Fuzzy.prepare(`${a.icon} `),
        entry: a
    }))

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        if (root.sloppySearch) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0]
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUndescoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    function guessIcon(str) {
        if (!str || str.length == 0) return "image-missing";

        // Quickshell's desktop entry lookup
        const entry = DesktopEntries.byId(str);
        if (entry) return entry.icon;

        // Normal substitutions
        if (substitutions[str]) return substitutions[str];
        if (substitutions[str.toLowerCase()]) return substitutions[str.toLowerCase()];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        // Icon exists -> return as is
        if (iconExists(str)) return str;


        // Simple guesses
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased)) return lowercased;

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName)) return reverseDomainNameAppName;

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName)) return lowercasedDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess)) return kebabNormalizedGuess;

        const undescoreToKebabGuess = getUndescoreToKebabAppName(str);
        if (iconExists(undescoreToKebabGuess)) return undescoreToKebabGuess;

        // Search in desktop entries
        const iconSearchResults = Fuzzy.go(str, preppedIcons, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        // Quickshell's desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry) return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
