# SCOM-NetApp
This is the SCOM management pack I created to monitor Netapp volumes.  This is the first version with basic volume discovery and used space monitor.  I plan to add additional monitors and discoveries as time permits.

In order to get something up to the blog site quickly, I only posted the XML.  I will eventually get the Visual Studio code posted.  This MP works by using a management server as a proxy for gather the Netapp data.

The initial discovery is based on a registry value on a SCOM management server.  Upon discovery of this item, the server is added as a Netapp computer proxy.  There is aregistry string which contains a comma separated list of the Netapp clusters.  Once detected the Netapp Clusters are discovered.  After the Netapp clusters are discovered, the volumes are discovered.  In very simple terms, that is how it works.

There are only a few basic steps to get this working.  First import the management pack into SCOM.  Then add a registry entry at HKLM\SOFTWARE\WSH\NetApp\Controllers.  Controllers should be a string with a comma separated list of the Netapp cluster names.  Then let the magic begin.

The management pack can be downloaded here in the bin\release folder.  https://github.com/dpsmith005/SCOM-NetApp/tree/main/Windows.Computer.Netapp/bin/Release