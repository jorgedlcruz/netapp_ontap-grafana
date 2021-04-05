Grafana Dashboard for NetApp ONTAP v9.8+ RESTful API
===================

![alt tag](https://www.jorgedelacruz.es/wp-content/uploads/2021/04/2021-04-04_0-09-30.png)

This project consists in a Bash Shell script to retrieve the NetApp ONTAP information, directly from the RESTfulAPI, about Cluster, SVM, Volumes, LUN, metrics, and much more. The information is being saved it into InfluxDB output directly into the InfluxDB database using curl, then in Grafana: a Dashboard is created to present all the information.

----------

### Getting started
You can follow the steps on the next Blog Post - 

Or try with this simple steps:
* Download the netapp_ontap.sh file and change the parameters under Configuration, like username/password, etc. with your real data
* Make the script executable with the command chmod +x netapp_ontap.sh
* Run the netapp_ontap.sh and check on Chronograf, or in Grafana Explorer, that you can retrieve the information properly
* Schedule the script execution, for example every 5 minutes using crontab
* Download the Grafana Dashboard JSON file and import it into your Grafana
* Enjoy :)

----------

### Additional Information
* Nothing to add as of today

### Known issues 
Would love to see some known issues and keep opening and closing as soon as I have feedback from you guys. Fork this project, use it and please provide feedback.
