-- Activate VS Code and copy Problems panel content
tell application "Visual Studio Code" to activate
delay 0.02

-- Use VS Code's command palette to focus on Problems panel
do shell script "osascript -e 'tell application \"System Events\" to keystroke \"p\" using {command down, shift down}'"
delay 0.1
do shell script "osascript -e 'tell application \"System Events\" to keystroke \"workbench.action.problems.focus\"'"
delay 0.1
do shell script "osascript -e 'tell application \"System Events\" to key code 36'" -- Press Enter

delay 0.2 -- Wait for the Problems panel to focus

-- Select and copy the content
tell application "System Events"
	keystroke "a" using {command down} -- Select all
	delay 0.1
	keystroke "c" using {command down} -- Copy
	delay 0.05
end tell

-- Get the clipboard contents
set problemsContent to the clipboard

-- Sanitize and escape the clipboard contents
set sanitizedContent to do shell script "echo " & quoted form of problemsContent & " | perl -pe 's/[\\\\\"]/\\\\$&/g' | perl -pe 's/\\n/\\\\n/g' | tr -d '\\r'"

-- Log the sanitized content (for debugging)
log "Sanitized content: " & sanitizedContent

-- Activate Google Chrome
tell application "Google Chrome"
	activate
	
	-- Check if Claude.ai tab is open and switch to it
	set claudeTabFound to false
	set windowIndex to 1
	repeat with w in windows
		set tabIndex to 1
		repeat with t in tabs of w
			if URL of t contains "claude.ai" then
				set active tab index of w to tabIndex
				set index of w to 1
				set claudeTabFound to true
				exit repeat
			end if
			set tabIndex to tabIndex + 1
		end repeat
		if claudeTabFound then exit repeat
		set windowIndex to windowIndex + 1
	end repeat
	
	-- If Claude.ai tab is not found, prompt user to open it
	if not claudeTabFound then
		display dialog "Please open https://claude.ai in Google Chrome, then run this script again." buttons {"OK"} default button "OK"
		return
	end if
	
	-- Find the chat input area, paste the sanitized content, and press Enter
	set success to false
	repeat 5 times -- Try up to 5 times
		tell active tab of front window
			execute javascript "
                function pasteAndSend(content) {
                    return new Promise((resolve) => {
                        console.log('Starting pasteAndSend function');
                        console.log('Content to paste:', content);
                        setTimeout(() => {
                            const inputArea = document.querySelector('div[contenteditable=\"true\"].ProseMirror');
                            console.log('Input area found:', inputArea);
                            if (inputArea) {
                                console.log('Setting innerHTML');
                                inputArea.innerHTML = content;
                                console.log('Content pasted');
                                console.log('Dispatching input event');
                                inputArea.dispatchEvent(new Event('input', { bubbles: true }));
                                
                                setTimeout(() => {
                                    console.log('Looking for send button');
                                    const sendButton = document.querySelector('button[aria-label=\"Send message\"], button[aria-label=\"Send Message\"]');
                                    console.log('Send button found:', sendButton);
                                    if (sendButton) {
                                        console.log('Clicking send button');
                                        sendButton.click();
                                        console.log('Send button clicked');
                                        resolve('true');
                                    } else {
                                        console.error('Send button not found');
                                        resolve('false');
                                    }
                                }, 500); // Wait 500ms before clicking send
                            } else {
                                console.error('Chat input area not found');
                                resolve('false');
                            }
                        }, 1000); // Wait 1s before pasting
                    });
                }
                
                pasteAndSend('" & sanitizedContent & "').then(result => {
                    window.pasteAndSendResult = result;
                }).catch(error => {
                    console.error('Error in pasteAndSend:', error);
                    window.pasteAndSendResult = 'false';
                });
            "
			
			-- Wait for the operation to complete
			delay 0.02
			
			-- Check the result
			set jsResult to execute javascript "window.pasteAndSendResult || 'false'"
			if jsResult is "true" then
				set success to true
				exit repeat
			end if
		end tell
		
		if not success then
			delay 0.02 -- Wait 2 seconds before trying again
		end if
	end repeat
	
	
end tell