// Tile the given windows.
const tileWindows = function(screenNum, clients, gap=2) {
  let screenRect = workspace.clientArea(workspace.MaximizeArea, screenNum, workspace.currentDesktop);
  let nextX = screenRect.x;

  // Limit to three windows, given these portions of the screen width:
  const widths = [0.30, 0.34, 0.36];

  for (let i=0; i<widths.length; ++i) {
    const rect = {
      x: nextX,
      y: screenRect.y,
      width: screenRect.width * widths[i],
      height: screenRect.height,
    };

    nextX = rect.x + rect.width;

    rect.x += gap;
    rect.y += gap;
    rect.width -= gap * 2;
    rect.height -= gap * 2;

    if (clients[i]) clients[i].frameGeometry = rect;
  }
};

// Move windows to where I like them to be.
const arrangeWindows = function() {
  let emacsWindows = [];

  workspace.clientList().forEach(client => {
    if (client.desktop == workspace.currentDesktop) {
      if (client.resourceClass == "emacs") {
        emacsWindows.push(client);
      } else if (client.caption.match(/Messages for web/)) {
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

  // Order the windows from left to right, then tile N of them:
  emacsWindows.sort((a, b) => a.frameGeometry.x - b.frameGeometry.x);
  tileWindows(0, emacsWindows.filter(client => client.screen == 0).slice(0, 3));
};

const printAllWindows = function() {
  workspace.clientList().forEach(client =>
    print(client.caption + " " + client.frameGeometry));
};

registerShortcut("Arrange Windows", "Arrange Windows", "Meta+A", arrangeWindows);
