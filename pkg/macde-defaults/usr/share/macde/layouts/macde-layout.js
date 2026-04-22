const baseUnit = typeof gridUnit === "undefined" ? 18 : gridUnit;
const dockLaunchers = [
    "preferred://browser",
    "applications:org.kde.dolphin.desktop",
    "applications:firefox-esr.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:vlc.desktop",
    "applications:systemsettings.desktop"
];

function safeAddWidget(panel, name) {
    try {
        return panel.addWidget(name);
    } catch (error) {
        print("Unable to add widget " + name + ": " + error);
        return null;
    }
}

function safeRemoveExistingPanels() {
    if (typeof panelIds !== "undefined") {
        for (const panelId of panelIds) {
            const existingPanel = panelById(panelId);
            if (existingPanel) {
                existingPanel.remove();
            }
        }
        return;
    }

    if (typeof panels === "function") {
        for (const existingPanel of panels()) {
            existingPanel.remove();
        }
    }
}

safeRemoveExistingPanels();

for (const desktop of desktops()) {
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", "file:///usr/share/macde/wallpapers/mountain.svg");
}

const topPanel = new Panel;
topPanel.location = "top";
topPanel.height = Math.round(baseUnit * 1.5);

safeAddWidget(topPanel, "org.kde.plasma.kickoff") ||
    safeAddWidget(topPanel, "org.kde.plasma.kicker") ||
    safeAddWidget(topPanel, "org.kde.plasma.applicationsmenu");
safeAddWidget(topPanel, "org.kde.plasma.appmenu");

const topSpacer = safeAddWidget(topPanel, "org.kde.plasma.panelspacer");
if (topSpacer) {
    topSpacer.currentConfigGroup = ["General"];
    topSpacer.writeConfig("expanding", "true");
}

safeAddWidget(topPanel, "org.kde.plasma.systemtray");

const clock = safeAddWidget(topPanel, "org.kde.plasma.digitalclock");
if (clock) {
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("showDate", "true");
}

const dock = new Panel;
dock.location = "bottom";
dock.alignment = "center";
dock.hiding = "windowsgobelow";
dock.height = Math.round(baseUnit * 2.9);
dock.length = Math.round(baseUnit * 56);
dock.minimumLength = Math.round(baseUnit * 56);
dock.maximumLength = Math.round(baseUnit * 56);

const taskWidget = safeAddWidget(dock, "org.kde.plasma.icontasks") ||
    safeAddWidget(dock, "org.kde.plasma.taskmanager");
if (taskWidget) {
    taskWidget.currentConfigGroup = ["General"];
    taskWidget.writeConfig("launchers", dockLaunchers.join(","));
    taskWidget.writeConfig("launchers59", dockLaunchers.join(","));
    taskWidget.writeConfig("showOnlyIcons", "true");
}
