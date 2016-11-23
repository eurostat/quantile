macro upload_to_eurobase
------------------------

Through the use of this SAS macro, the user can:
 - upload data to Eurobase, or 
 - validate files for Eurobase, or 
 - getting feedback on a file based on a feedback number 
by calling the webservice. 

The macro aims at replacing the old approach that consisted in sending an email to REFERENCE DBA.

See the documentation in Z:/Upload/doc/.
 
file ws-client
--------------
 
The macro above calls the ws-client.jar file to upload data directly to the ws-server. 

See the page: https://webgate.ec.europa.eu/CITnet/confluence/display/EUROBASE/UploadService+-+Client+documentation
and its subpage (e.g., https://webgate.ec.europa.eu/CITnet/confluence/pages/viewpage.action?spaceKey=EUROBASE&title=UploadService+-+Client+package+download).