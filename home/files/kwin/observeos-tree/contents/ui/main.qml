import QtQuick;
import org.kde.kwin;
import "../code/tree.js" as Tree;

Item {
    id: root;

    Timer {
        interval: 40;
        running: true;
        repeat: true;
        onTriggered: Tree.tick(Workspace, Qt);
    }

    Component.onCompleted: {
        Tree.init(Workspace, Qt);
        print("OBSERVEOS_TREE: controller initialized");
    }
}
