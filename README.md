# Jamf-Interaction-Toolkit

I'll have a more pmprehensive readme later

You can uses this verison right off the bat for testing.

Video from PDX MacAdmins Meetup: 
PDF of Presentation: https://www.dropbox.com/s/i45csew68cri3cd/PDX%20MacAdmins%20meetup%20-%20Apr%202018.pdf?dl=0

# Customized Branding

Update the "title" and any desired icon paths in the following scripts
* 00-UEX-Jamf-Interaction-no-grep.sh
* 00-uexblockagent-jss.sh
* 00-uexlogoutagent-jss.sh
* 00-uexrestartagent-jss.sh

If you want to add the icons in the jamfHelper & CocoaDialog windows
* Add them in the Payload inside the packages folder
* Set the owner:group to 'root:wheel' (chown root:wheel $targetFile)
* Set the RW mode to 755 (chmod 755 $targetFile)
* Then to create your UEXresource package run the "build_pkg.sh"

If you want to update the title and icon in the PleaseWait.app open the project in xcode from the PleaseWaitMini folder
* Go the MainMenu.XIP and change the title in the incpeter attributes
* to update icon simply replace the PleaseWait.icns
* Build your project with your teamID/Cert 
* Replace the PleaseWait.app that's in the payload
* Set the owner:group to 'root:wheel' (chown -R root:wheel $
* Set the RW mode to 755 (chmod -R 755 $targetFile)
* don't forget to make a new UEX resource package

# How to upload to your jamf Pro server

*  Create your UEXresourcesInstaller PKG with build.sh
*  Upload the Pakcage to your jamf Pro Server
*  Upload the 'UEX - Deferral Detection.xml' Extension Attibute to your jamf Pro Server
*  Upload all the scripts in the 'Scripts' folder to your jamf Pro Server
*  Open and edit the 'UEX Jamf Pro configuration tool.sh' with your UEX Resouce PKG name, and the jamf pro URL + credentials
*  Run the script 

# More coming soon on paramters and use cases  and imagery and "all that Jazz" 

