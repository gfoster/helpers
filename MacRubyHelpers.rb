def showFileSelector(sender)
    # Create the File Open Dialog class.
    dialog = NSOpenPanel.openPanel
    # Disable the selection of files in the dialog.
    dialog.canChooseFiles = false
    # Enable the selection of directories in the dialog.
    dialog.canChooseDirectories = true
    # Disable the selection of multiple items in the dialog.
    dialog.allowsMultipleSelection = false

    # Display the dialog and process the selected folder
    if dialog.runModalForDirectory(nil, file:nil) == NSOKButton
        # if we had a allowed for the selection of multiple items
        # we would have want to loop through the selection
       return dialog.filenames.first
    else
        return nil
    end
end
