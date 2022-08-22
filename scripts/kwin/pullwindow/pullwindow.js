/*
 * Pull the active window to the first screen, and center it.  When
 * applied again put it back to where it was.
 */
class PullWindow {
  constructor() {
    this.lastPos = null;
    this.windowId = null;
    this.portion = 0.75;
  }

  // Move a window to the main screen and center it.
  pull() {
    const client = workspace.activeClient;
    const id = client && client.windowId;
    if (!id) return;

    // Different window, restore previous window.
    if (this.windowId && id != this.windowId) this.restore();

    if (this.windowId && id == this.windowId) {
      // Already centered, restore
      this.restore();
    } else {
      this.lastPos = JSON.parse(JSON.stringify(client.frameGeometry));
      this.windowId = client.windowId;

      const screen = workspace.clientArea(workspace.MaximizeArea, 0, workspace.currentDesktop);
      const width = screen.width * this.portion;
      const height = screen.height * this.portion;
      const x = screen.x + Math.floor((screen.width - width)/2);
      const y = screen.y + Math.floor((screen.height - height)/2);

      client.frameGeometry = {x, y, width, height};
      workspace.activeClient = client; // Force raise the window.
    }
  }

  // Put a window back to where it was.
  restore() {
    if (!this.windowId || !this.lastPos) return;
    const window = workspace.getClient(this.windowId);
    if (window) window.frameGeometry = this.lastPos;
    this.windowId = null;
    this.lastPos = null;
  }
}

var pullWindow = new PullWindow();
registerShortcut("Pull Window", "Pull Window", "Meta+C", () => pullWindow.pull());
