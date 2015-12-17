#--------------------------------------------------------------------------------------------------------
#Author:   Shaz
#Purpose:  Fetches events specifically relating to Avecto Privilege Guard block messages. Service tag and date of event are required.
#Date:     16/01/2015
#Version:  1.0.0
#Edit:     1.1.0 Shaz> Updated the date search so that it includes an After and Before date range. This means the results should be more specific.
#                      Added a shortcut 'ddd' which when typed will default to today's date meaning you don't need to type the date if it is for today.
#                      Amended the eventlog criteria from searching for strings to instanceID. Should return results slightly more quicker.
#          1.1.1 Shaz> Changed the log file path to a variable and added the service tag to the log file name so it is easier to find.
#          1.1.2 Shaz> Added a ping test first, if machine does not ping, exit. Else, continue with search.
#          1.1.3 Shaz> Open the event-log folder just before search commences.
#---------------------------------------------------------------------------------------------------------

#Create a directory and log the console output to a text file
New-Item -ItemType Directory -Force -Path C:\ProgramData\eventviewer-logs

#Prompt for service tag and date.
$serviceTag = Read-Host 'Service Tag '
$fromDate = Read-Host 'Provide date-range FROM (dd/mm/yyyy) '

#Check if the machine pings, exit if it does not
If (!(Test-Connection -Cn $serviceTag -BufferSize 16 -Count 1 -ea 0 -quiet))
    {
        Read-Host -Prompt "Machine is not pinging.`nPress Enter to exit"
    }

#Machine pings so continue with search
Else
    {

        $logPath = "C:\ProgramData\eventviewer-logs\" + $serviceTag + "-$(((get-date).ToUniversalTime()).ToString("yyyymmdd-ThhmmssZ")).txt"

        #Begin logging
        $ErrorActionPreference="SilentlyContinue"
        Stop-Transcript | out-null
        $ErrorActionPreference = "Continue"
        Start-Transcript -path $logPath -append

        #Determine the date range: if 'ddd' is the input then obtain today's date else use the input as the date range (e.g. 01/01/2001)
        If ($fromDate -eq 'ddd')
            {
                $startDate = Get-Date -format d #format the date, nothing else needs to be done to this date.
                $endDate = Get-Date #don't format the date first
                $endDate.AddDays(1) #add a day
                Get-Date $endDate -format d #now format the day after adding a day, formatting at the same time results in an error because the date object is converted into a string.
            }

        Else
            {
                $startDate = Get-Date $fromDate
                $endDate = $startDate.AddDays(1)
                Get-Date $startDate -format d
                Get-Date $endDate -format d
            }

        #Provide feedback that fetching has started
        Write-Verbose -Message "Fetching Events from machine." -verbose
        
        #Open the location of the logs... no real benefit here, just feeling lazy
        ii "C:\ProgramData\eventviewer-logs\"
        
        #Search the event log for InstanceID 116 which relates to APG. Use the variables from above for dates and service tag.
        Get-EventLog -logname application -InstanceID 116 -After $startDate -Before $endDate -ComputerName $serviceTag | format-list | out-default

        #Provide feedback that fetching has finished
        Write-Verbose -Message "Finished fetching events." -verbose

        #Stop logging
        Stop-Transcript

        Exit
}