var EOSCopyToClipboard = EOSCopyToClipboard || {};

EOSCopyToClipboard.showToast = function () {
    // Try to access parent document (BC page context)
    var targetDoc = document;
    
    try {
        if (window.parent && window.parent.document && window.parent.document.body) {
            targetDoc = window.parent.document;
        }
    } catch (e) {
        // Try grandparent
        try {
            if (window.parent.parent && window.parent.parent.document && window.parent.parent.document.body) {
                targetDoc = window.parent.parent.document;
            }
        } catch (e2) {
            // Use current document
        }
    }

    // Remove existing toast
    var existingToast = targetDoc.getElementById('eos-copy-toast');
    if (existingToast) {
        existingToast.remove();
    }

    // Create toast
    var toast = targetDoc.createElement('div');
    toast.id = 'eos-copy-toast';
    toast.innerText = '✓ Copied!';
    toast.style.cssText = 'position:fixed!important;top:50%!important;left:50%!important;transform:translate(-50%,-50%)!important;background:#fff!important;color:#333!important;padding:15px 25px!important;border-radius:8px!important;box-shadow:0 4px 20px rgba(0,0,0,0.3)!important;font-family:Segoe UI,sans-serif!important;font-size:16px!important;font-weight:600!important;z-index:2147483647!important;border:1px solid #ccc!important;';

    targetDoc.body.appendChild(toast);

    // Auto-hide
    setTimeout(function () {
        if (toast && toast.parentNode) {
            toast.parentNode.removeChild(toast);
        }
    }, 1200);
};

function CopyToClipboard(textToCopy) {
    if (!textToCopy) {
        return;
    }

    // Use the modern Clipboard API if available
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(textToCopy)
            .then(function () {
                EOSCopyToClipboard.showToast();
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnCopyCompleted', []);
            })
            .catch(function (err) {
                // Fallback to execCommand
                EOSCopyToClipboard.fallbackCopy(textToCopy);
            });
    } else {
        // Fallback for older browsers
        EOSCopyToClipboard.fallbackCopy(textToCopy);
    }
}

EOSCopyToClipboard.fallbackCopy = function (textToCopy) {
    var textArea = document.createElement('textarea');
    textArea.value = textToCopy;
    textArea.style.position = 'fixed';
    textArea.style.left = '-9999px';
    textArea.style.top = '-9999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
        document.execCommand('copy');
        EOSCopyToClipboard.showToast();
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnCopyCompleted', []);
    } catch (err) {
        console.error('Failed to copy text: ', err);
    }

    document.body.removeChild(textArea);
};
