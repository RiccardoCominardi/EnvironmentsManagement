controladdin "EOS Restore Copy Clipboard"
{
    RequestedHeight = 0;
    RequestedWidth = 0;
    MinimumHeight = 0;
    MinimumWidth = 0;
    MaximumHeight = 0;
    MaximumWidth = 0;
    VerticalStretch = false;
    HorizontalStretch = false;
    VerticalShrink = true;
    HorizontalShrink = true;

    Scripts = 'src/controladdin/scripts/EOSRestoreCopyClipboard.js';
    StyleSheets = 'src/controladdin/styles/EOSRestoreCopyClipboard.css';
    StartupScript = 'src/controladdin/scripts/EOSRestoreCopyClipboardStartup.js';

    event OnControlReady();
    event OnCopyCompleted();
    procedure CopyToClipboard(TextToCopy: Text);
}
