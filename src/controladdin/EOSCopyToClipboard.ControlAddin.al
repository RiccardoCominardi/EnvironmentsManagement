controladdin "EOS Copy To Clipboard"
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

    Scripts = 'src/controladdin/scripts/EOSCopyToClipboard.js';
    StyleSheets = 'src/controladdin/styles/EOSCopyToClipboard.css';
    StartupScript = 'src/controladdin/scripts/EOSCopyToClipboardStartup.js';

    event OnControlReady();
    event OnCopyCompleted();

    procedure CopyToClipboard(TextToCopy: Text);
}
