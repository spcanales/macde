const baseUnit = typeof gridUnit === "undefined" ? 18 : gridUnit;
const dockLaunchers = [
    "applications:org.kde.dolphin.desktop",
    "applications:firefox-esr.desktop",
    "applications:org.kde.kate.desktop",
    "applications:org.kde.gwenview.desktop",
    "applications:org.kde.okular.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.spectacle.desktop",
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

for (const panelId of panelIds) {
    const existingPanel = panelById(panelId);
    if (existingPanel) {
        existingPanel.remove();
    }
}

for (const desktop of desktops()) {
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", "file:///usr/share/macde/wallpapers/sunrise.svg");
}

const topPanel = new Panel;
topPanel.location = "top";
topPanel.height = Math.round(baseUnit * 1.5);

safeAddWidget(topPanel, "org.kde.plasma.kickoff");
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
dock.length = Math.round(baseUnit * 44);

const iconTasks = safeAddWidget(dock, "org.kde.plasma.icontasks");
if (iconTasks) {
    iconTasks.currentConfigGroup = ["General"];
    iconTasks.writeConfig("launchers", dockLaunchers.join(","));
}
