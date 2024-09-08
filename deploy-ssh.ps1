# Check if the required arguments are passed
if ($args.Count -lt 4) {
    Write-Host "Usage: script.ps1 <SSH_IP> <SSH_USER> <REMOTE_PATH> <DEST_FOLDER_NAME>"
    exit 1
}

# Assign the CLI arguments to variables
$sshIP = $args[0]
$sshUser = $args[1]
$remotePath = $args[2]
$destFolderName = $args[3]

# Validate that all arguments are provided
if (-not $sshIP -or -not $sshUser -or -not $remotePath -or -not $destFolderName) {
    Write-Host "Error: All four arguments (SSH_IP, SSH_USER, REMOTE_PATH, DEST_FOLDER_NAME) are required."
    exit 1
}

# Determine the folder the script is in
$sourceFolder = (Get-Location).Path

# Ensure the destination folder is properly constructed
$remoteDestPath = "${remotePath}/${destFolderName}"

# Print paths for debugging
Write-Host "Source folder: $sourceFolder"
Write-Host "Remote destination: $remoteDestPath"

# Properly quote the paths to handle spaces in folder names
$quotedSourceFolder = '"' + $sourceFolder + '/."'  # Quotes around the local source folder path and the '.' to indicate current folder content
$quotedRemoteDestPath = "${sshUser}@${sshIP}:${remoteDestPath}"  # Destination path with single quotes around the remote path

# Construct the SCP command to recursively copy the contents of the folder
$scpCommand = "scp -r $quotedSourceFolder $quotedRemoteDestPath"

# Print the SCP command for debugging purposes
Write-Host "Running SCP command: $scpCommand"

try {
    # Create remote directory if it doesn't exist
    $createDirCommand = "ssh $sshUser@$sshIP 'rm -rf ${remoteDestPath} && mkdir -p ${remoteDestPath}'"
    Write-Host "Recreating mod directory: $createDirCommand"
    Invoke-Expression $createDirCommand

    # Use Start-Process to execute the SCP command
    Start-Process "scp" -ArgumentList "-r", "$sourceFolder/*", "$quotedRemoteDestPath" -Wait -NoNewWindow
    Write-Host "Files transferred successfully to $remoteDestPath on $sshIP."
} catch {
    Write-Host "Error occurred during SCP transfer: $_"
}
