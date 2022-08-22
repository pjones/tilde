/*
  Manage a list of windows that you can jump between with a single
  keystroke.
*/
class JumpList {
  constructor() {
    this.clear();
  }

  // Remove all windows from the jump list.
  clear() {
    this.windowIds = [];
    this.index = 0;
  }

  // Add or remove the current window from the jump list.
  toggleCurrentWindow() {
    const client = workspace.activeClient;
    const id = client && client.windowId;
    const index = id && this.windowIds.indexOf(id);

    if (id && index == -1) {
      this.windowIds.push(client.windowId);
      this.index = this.windowIds.length - 1;
    } else if (id && index >= 0) {
      this.windowIds.splice(index, 1);
      this.index = 0;
    }
  }

  // Jump to the next window in the jump list.
  jump() {
    const length = this.windowIds.length;

    if (length <= 0) return;
    this.index = ++this.index % length;

    // Is the window we want to jump to the active window?
    const current = workspace.activeClient;
    if (current && current.windowId == this.windowIds[this.index]) {
      if (length == 1) return; // No other window to jump to.
      this.index = ++this.index % length; // Try next window.
    }

    const window = workspace.getClient(this.windowIds[this.index]);
    if (window) workspace.activeClient = window;
  }
}

var jumpList = new JumpList();

registerShortcut("Toggle Jump List", "Toggle Jump List", "Meta+\"",
                 () => jumpList.toggleCurrentWindow());

registerShortcut("Clear Jump List", "Clear Jump List", "Meta+Alt+'",
                 () => jumpList.clear());

registerShortcut("Jump to Window", "Jump to Window", "Meta+'",
                 () => jumpList.jump());
