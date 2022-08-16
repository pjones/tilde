// Move windows to where I like them to be.
const arrangeWindows = function() {
  workspace.clientList().forEach(client => {
    if (client.desktop == workspace.currentDesktop) {
      if (client.caption.match(/Messages for web/)) {
        client.frameGeometry = {x: 18, y: 874, width: 775, height: 990};
      } else if (client.caption.match(/Signal/)) {
        client.frameGeometry = {x: 800, y: 874, width: 890, height: 990};
      } else if (client.caption.match(/Telegram Web/)) {
        client.frameGeometry = {x: 1699, y: 874, width: 846, height: 990};
      } else if (client.caption.match(/Outlook/)) {
        client.frameGeometry = {x: 2560, y: 0, width: 748, height: 524};
      } else if (client.caption.match(/Ubuntu RFA/)) {
        client.frameGeometry = {x: 3310, y: 0, width: 690, height: 524};
      } else if (client.caption.match(/Mattermost/)) {
        client.frameGeometry = {x: 2560, y: 526, width: 1440, height: 1056};
      } else if (client.caption.match(/GitLab/)) {
        client.frameGeometry = {x: 2560, y: 1584, width: 1440, height: 910};
      }
    }
  });
};

const printAllWindows = function() {
  workspace.clientList().forEach(client =>
    print(client.caption + " " + client.frameGeometry));
};

registerShortcut("Arrange Windows", "Arrange Windows", "Meta+A", arrangeWindows);
