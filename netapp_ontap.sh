#!/bin/bash
##      .SYNOPSIS
##      Grafana Dashboard for NetApp ONTAP - Using RestAPI to InfluxDB Script
## 
##      .DESCRIPTION
##      This Script will query the NetApp ONTAP RestAPI and send the data directly to InfluxDB, which can be used to present it to Grafana. 
##      The Script and the Grafana Dashboard it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##      .Notes
##      NAME:  netapp_ontap.sh
##      ORIGINAL NAME: netapp_ontap.sh
##      LASTEDIT: 02/04/2021
##      VERSION: 1.0
##      KEYWORDS: NetApp, InfluxDB, Grafana
   
##      .Link
##      https://jorgedelacruz.es/
##      https://jorgedelacruz.uk/

##
# Configurations
##
# Endpoint URL for InfluxDB
netappInfluxDBURL="http://YOURINFLUXSERVERIP" #Your InfluxDB Server, http://FQDN or https://FQDN if using SSL
netappInfluxDBPort="8086" #Default Port
netappInfluxDB="telegraf" #Default Database
netappInfluxDBUser="USER" #User for Database
netappInfluxDBPassword='PASSWORD' #Password for Database

# Endpoint URL for login action
netappUsername="YOURONTAPUSER" #Your username with privileges to login into the ONTAP
netappPassword='YOURONTAPPASSWORD'
netappAuth=$(echo -ne "$netappUsername:$netappPassword" | base64);
netappRestServer="YOURONTAPSERVER"
netappMetrics="20" #They came in interval of 15 seconds, so 20 will be equal to the metrics of the last 5 minutes. If you want to run your script every 5 minutes, let it like this, if not, change it accordingly.

##
# NetApp ONTAP Cluster
##
netappONTAPUrl="https://$netappRestServer/api/cluster?return_records=true&return_timeout=15"
netappClusterUrl=$(curl -X GET "$netappONTAPUrl" -H "Accept:application/json" -H  "authorization: Basic $netappAuth" -H "Content-Length: 0" 2>&1 -k --silent)

    netappClusterName=$(echo "$netappClusterUrl" | jq --raw-output ".name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusterID=$(echo "$netappClusterUrl" | jq --raw-output ".uuid")    
    netappClusterVersion=$(echo "$netappClusterUrl" | jq --raw-output ".version.full" | awk -F':' '{print $1}' | awk '{gsub(/ /,"\\ ");print}')
    netappClusterVersiongen=$(echo "$netappClusterUrl" | jq --raw-output ".version.generation")
    netappClusterVersionmaj=$(echo "$netappClusterUrl" | jq --raw-output ".version.major")
    netappClusterVersionmin=$(echo "$netappClusterUrl" | jq --raw-output ".version.minor")
    netappClusterMgmNet=$(echo "$netappClusterUrl" | jq --raw-output ".management_interfaces[0].ip.address")
    
    ##Un-comment the following echo for debugging    
    #echo "netapp_cluster_overview,clustername=$netappClusterName,uuid=$netappClusterID,clusterversion=$netappClusterVersion,managementnetwork=$netappClusterMgmNet versiongeneration=$netappClusterVersiongen,versionmajor=$netappClusterVersionmaj,versionminor=$netappClusterVersionmin"
    
    ##Comment the Curl while debugging
    echo "Writing netapp_cluster_overview to InfluxDB"
    curl -i -XPOST "$netappInfluxDBURL:$netappInfluxDBPort/write?precision=s&db=$netappInfluxDB" -u "$netappInfluxDBUser:$netappInfluxDBPassword" --data-binary "netapp_cluster_overview,clustername=$netappClusterName,uuid=$netappClusterID,clusterversion=$netappClusterVersion,managementnetwork=$netappClusterMgmNet versiongeneration=$netappClusterVersiongen,versionmajor=$netappClusterVersionmaj,versionminor=$netappClusterVersionmin"


##
# NetApp ONTAP Aggregates
##
netappONTAPUrl="https://$netappRestServer/api/storage/aggregates?fields=space%2Cinactive_data_reporting.enabled%2Cstate%2Csnaplock_type%2Cspace.block_storage.inactive_user_data%2Cmetric%2C*"
netappClusterAggrUrl=$(curl -X GET "$netappONTAPUrl" -H "Accept:application/json" -H  "authorization: Basic $netappAuth" -H "Content-Length: 0" 2>&1 -k --silent)

declare -i arrayaggregates=0
for row in $(echo "$netappClusterAggrUrl" | jq -r '.records[].uuid'); do
    
    netappClusteraggregateID=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].uuid")
    netappClusteraggregateName=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusteraggregateNodeID=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].node.uuid")
    netappClusteraggregateNodeName=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].node.name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusteraggregatespacefootprint=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].space.footprint")
    netappClusteraggregatespaceblockstoragesize=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].space.block_storage.size")
    netappClusteraggregatespaceblockstorageavailable=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].space.block_storage.available")
    netappClusteraggregatespaceblockstorageused=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].space.block_storage.used")
    netappClusteraggregatespacecloudstorageused=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].space.cloud_storage.used")
    netappClusteraggregatespaceeffsavings=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].space.efficiency.savings")
    netappClusteraggregatespaceeffratio=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].space.efficiency.ratio")
    netappClusteraggregatespaceefflogical=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].space.efficiency.logical_used")
    netappClusteraggregatestate=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].state")
    netappClusteraggregatesnaplock=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].snaplock_type")
    netappClusteraggregateblockprimarydiskcount=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].block_storage.primary.disk_count")
    netappClusteraggregateblockprimarydiskclass=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].block_storage.primary.disk_class")
    netappClusteraggregateblockprimaryraidtype=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].block_storage.primary.raid_type")
    netappClusteraggregateblockprimaryraidsize=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].block_storage.primary.raid_size")
    netappClusteraggregateblockhybrid=$(echo "$netappClusterAggrUrl" | jq --raw-output ".records[$arrayaggregates].block_storage.hybrid_cache.enabled")
    
    ##Un-comment the following echo for debugging    
    #echo "netapp_aggregate_overview,clustername=$netappClusterName,aggregateName=$netappClusteraggregateName,aggregateNodename=$netappClusteraggregateNodeName,aggregateID=$netappClusteraggregateID,aggregateNodeID=$netappClusteraggregateNodeID,aggregatestate=$netappClusteraggregatestate,aggregatesnaplock=$netappClusteraggregatesnaplock,storagehybrid=$netappClusteraggregateblockhybrid spacefootprint=$netappClusteraggregatespacefootprint,spaceblockstoragesize=$netappClusteraggregatespaceblockstoragesize,spaceblockstorageavailable=$netappClusteraggregatespaceblockstorageavailable,spaceblockstorageused=$netappClusteraggregatespaceblockstorageused,spacecloudstorageused=$netappClusteraggregatespacecloudstorageused,efficiencysavings=$netappClusteraggregatespaceeffsavings,efficencyratio=$netappClusteraggregatespaceeffratio,efficiencylogical=$netappClusteraggregatespaceefflogical,diskcount=$netappClusteraggregateblockprimarydiskcount,diskclass=$netappClusteraggregateblockprimarydiskclass,diskraidtype=$netappClusteraggregateblockprimaryraidtype,diskraidsize=$netappClusteraggregateblockprimaryraidsize"
    
    ##Comment the Curl while debugging
    echo "Writing netapp_aggregate_overview to InfluxDB"
    curl -i -XPOST "$netappInfluxDBURL:$netappInfluxDBPort/write?precision=s&db=$netappInfluxDB" -u "$netappInfluxDBUser:$netappInfluxDBPassword" --data-binary "netapp_aggregate_overview,clustername=$netappClusterName,aggregateName=$netappClusteraggregateName,aggregateNodename=$netappClusteraggregateNodeName,aggregateID=$netappClusteraggregateID,aggregateNodeID=$netappClusteraggregateNodeID,aggregatestate=$netappClusteraggregatestate,aggregatesnaplock=$netappClusteraggregatesnaplock,storagehybrid=$netappClusteraggregateblockhybrid,diskclass=$netappClusteraggregateblockprimarydiskclass,diskraidtype=$netappClusteraggregateblockprimaryraidtype spacefootprint=$netappClusteraggregatespacefootprint,spaceblockstoragesize=$netappClusteraggregatespaceblockstoragesize,spaceblockstorageavailable=$netappClusteraggregatespaceblockstorageavailable,spaceblockstorageused=$netappClusteraggregatespaceblockstorageused,spacecloudstorageused=$netappClusteraggregatespacecloudstorageused,efficiencysavings=$netappClusteraggregatespaceeffsavings,efficencyratio=$netappClusteraggregatespaceeffratio,efficiencylogical=$netappClusteraggregatespaceefflogical,diskcount=$netappClusteraggregateblockprimarydiskcount,diskraidsize=$netappClusteraggregateblockprimaryraidsize"
    
    arrayaggregates=$arrayaggregates+1
done

##
# NetApp ONTAP Volumes
##
netappONTAPUrl="https://$netappRestServer/api/storage/volumes?return_timeout=120&fields=uuid%2Cname%2Csvm%2Csize%2Cstate%2Caggregates%2Cspace%2Ctiering%2Cstyle%2Cis_svm_root%2Cguarantee%2Cmovement%2Cspace.block_storage_inactive_user_data"
netappClustervolumesUrl=$(curl -X GET "$netappONTAPUrl" -H "Accept:application/json" -H  "authorization: Basic $netappAuth" -H "Content-Length: 0" 2>&1 -k --silent)

declare -i arrayvolumes=0
for row in $(echo "$netappClustervolumesUrl" | jq -r '.records[].uuid'); do
    
    netappClustervolumeID=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].uuid")
    netappClustervolumeName=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].name" | awk '{gsub(/ /,"\\ ");print}')
    netappClustervolumeSize=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].size")
    netappClustervolumeState=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].state")
    netappClustervolumeStyle=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].style")
    netappClustervolumeAggrName=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].aggregates[0].name" | awk '{gsub(/ /,"\\ ");print}')
    netappClustervolumeAggrID=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].aggregates[0].uuid")
    netappClustervolumeSVMName=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].svm.name" | awk '{gsub(/ /,"\\ ");print}')
    netappClustervolumeSVMID=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].svm.id")
    netappClustervolumeSpaceSize=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.size")
    netappClustervolumeSpaceAvailable=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.available")
    netappClustervolumeSpaceUsed=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.used")
    netappClustervolumeSpaceLTF=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.local_tier_footprint")
    netappClustervolumeSpaceFootprint=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.footprint")
    netappClustervolumeSpaceOverprovisioned=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.over_provisioned")
    netappClustervolumeSpaceMetadata=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.metadata")
    netappClustervolumeSpaceTotalfootprint=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.total_footprint")
    netappClustervolumeSnapshotUsed=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.snapshot.used")
    netappClustervolumeSnapshotReserved=$(echo "$netappClustervolumesUrl" | jq --raw-output ".records[$arrayvolumes].space.snapshot.reserve_percent")
    
    ##Un-comment the following echo for debugging    
    #echo "netapp_volumes_overview,clustername=$netappClusterName,volumeName=$netappClustervolumeName,volumestate=$netappClustervolumeState,volumestyle=$netappClustervolumeStyle,aggregateName=$netappClustervolumeAggrName,SVMName=$netappClustervolumeSVMName volumesize=$netappClustervolumeSize,volumeSize=$netappClustervolumeSpaceSize,volumeAvailable=$netappClustervolumeSpaceAvailable,volumeUsed=$netappClustervolumeSpaceUsed,volumeLocalTierFootprint=$netappClustervolumeSpaceLTF,volumeFootprint=$netappClustervolumeSpaceFootprint,volumeOverprovisioned=$netappClustervolumeSpaceOverprovisioned,volumeMetadata=$netappClustervolumeSpaceMetadata,volumeTotalfootprint=$netappClustervolumeSpaceTotalfootprint,volumeSnapshotused=$netappClustervolumeSnapshotUsed,volumesnapshotReserved=$netappClustervolumeSnapshotReserved"
    
    ##Comment the Curl while debugging
    echo "Writing netapp_volumes_overview to InfluxDB"
    curl -i -XPOST "$netappInfluxDBURL:$netappInfluxDBPort/write?precision=s&db=$netappInfluxDB" -u "$netappInfluxDBUser:$netappInfluxDBPassword" --data-binary "netapp_volumes_overview,clustername=$netappClusterName,volumeName=$netappClustervolumeName,volumestate=$netappClustervolumeState,volumestyle=$netappClustervolumeStyle,aggregateName=$netappClustervolumeAggrName,SVMName=$netappClustervolumeSVMName volumesize=$netappClustervolumeSize,volumeSize=$netappClustervolumeSpaceSize,volumeAvailable=$netappClustervolumeSpaceAvailable,volumeUsed=$netappClustervolumeSpaceUsed,volumeLocalTierFootprint=$netappClustervolumeSpaceLTF,volumeFootprint=$netappClustervolumeSpaceFootprint,volumeOverprovisioned=$netappClustervolumeSpaceOverprovisioned,volumeMetadata=$netappClustervolumeSpaceMetadata,volumeTotalfootprint=$netappClustervolumeSpaceTotalfootprint,volumeSnapshotused=$netappClustervolumeSnapshotUsed,volumesnapshotReserved=$netappClustervolumeSnapshotReserved"
    
    arrayvolumes=$arrayvolumes+1
done

##
# NetApp ONTAP SVM
##
netappONTAPUrl="https://$netappRestServer/api/svm/svms?return_timeout=120&max_records=40&fields=name%2Cstate%2Csubtype%2Cipspace%2Caggregates%2Cnfs%2Ccifs%2Ciscsi%2Cnvme%2Cfcp%2Csnapmirror.is_protected%2Cs3&order_by=name"
netappClusterSVMUrl=$(curl -X GET "$netappONTAPUrl" -H "Accept:application/json" -H  "authorization: Basic $netappAuth" -H "Content-Length: 0" 2>&1 -k --silent)

declare -i arraysvm=0
for row in $(echo "$netappClusterSVMUrl" | jq -r '.records[].uuid'); do
    
    netappClusterSVMID=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].uuid")
    netappClusterSVMName=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusterSVMAggrName=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].aggregates[0].name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusterSVMAggrID=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].aggregates[0].uuid")
    netappClusterSVMState=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].state")
    netappClusterSVMIPspaceName=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].ipspace.name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusterSVMIPspaceID=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].ipspace.id")
    netappClusterSVMNFS=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].nfs.enabled")
            case $netappClusterSVMNFS in
            true)
                SVMNFS="1"
            ;;
            false)
                SVMNFS="2"
            ;;
            esac
    netappClusterSVMCIFS=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].cifs.enabled")
            case $netappClusterSVMCIFS in
            true)
                SVMCIFS="1"
            ;;
            false)
                SVMCIFS="2"
            ;;
            esac
    netappClusterSVMISCSI=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].iscsi.enabled")
            case $netappClusterSVMISCSI in
            true)
                SVMISCSI="1"
            ;;
            false)
                SVMISCSI="2"
            ;;
            esac
    netappClusterSVMFCP=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].fcp.enabled")
            case $netappClusterSVMFCP in
            true)
                SVMFCP="1"
            ;;
            false)
                SVMFCP="2"
            ;;
            esac
    netappClusterSVMNVME=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].nvme.enabled")
            case $netappClusterSVMNVME in
            true)
                SVMNVME="1"
            ;;
            false)
                SVMNVME="2"
            ;;
            esac
    netappClusterSVMSnapMirror=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].snapmirror.is_protected")
            case $netappClusterSVMSnapMirror in
            true)
                SVMSnapMirror="1"
            ;;
            false)
                SVMSnapMirror="2"
            ;;
            esac
    netappClusterSVMS3=$(echo "$netappClusterSVMUrl" | jq --raw-output ".records[$arraysvm].s3.enabled")
            case $netappClusterSVMS3 in
            true)
                SVMS3="1"
            ;;
            false)
                SVMS3="2"
            ;;
            esac

    ##Un-comment the following echo for debugging    
    #echo "netapp_SVM_overview,clustername=$netappClusterName,SVMName=$netappClusterSVMName,aggregateName=$netappClustervolumeAggrName,SVMState=$netappClusterSVMState,SVMIPspacename=$netappClusterSVMIPspaceName SVMNFS=$SVMNFS,SVMCIFS=$SVMCIFS,SVMISCSI=$SVMISCSI,SVMFCP=$SVMFCP,SVMNVME=$SVMNVME,SVMSnapMirror=$SVMSnapMirror,SVMS3=$SVMS3"
    
    ##Comment the Curl while debugging
    echo "Writing netapp_SVM_overview to InfluxDB"
    curl -i -XPOST "$netappInfluxDBURL:$netappInfluxDBPort/write?precision=s&db=$netappInfluxDB" -u "$netappInfluxDBUser:$netappInfluxDBPassword" --data-binary "netapp_SVM_overview,clustername=$netappClusterName,SVMName=$netappClusterSVMName,aggregateName=$netappClustervolumeAggrName,SVMState=$netappClusterSVMState,SVMIPspacename=$netappClusterSVMIPspaceName SVMNFS=$SVMNFS,SVMCIFS=$SVMCIFS,SVMISCSI=$SVMISCSI,SVMFCP=$SVMFCP,SVMNVME=$SVMNVME,SVMSnapMirror=$SVMSnapMirror,SVMS3=$SVMS3"
    
    arraysvm=$arraysvm+1
done

##
# NetApp ONTAP LUN
##
netappONTAPUrl="https://$netappRestServer/api/storage/luns?return_timeout=120&max_records=40&fields=svm%2Clocation%2Cos_type%2Cspace%2Cstatus%2Cserial_number%2Ccomment%2Cqos_policy%2Cmetric&status.container_state=online"
netappClusterLUNUrl=$(curl -X GET "$netappONTAPUrl" -H "Accept:application/json" -H  "authorization: Basic $netappAuth" -H "Content-Length: 0" 2>&1 -k --silent)

declare -i arraylun=0
for row in $(echo "$netappClusterLUNUrl" | jq -r '.records[].uuid'); do
    
    netappClusterLUNID=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].uuid")
    netappClusterLUNSVMName=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].svm.name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusterLUNName=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].name")
    netappClusterLUNLocation=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].location.logical_unit")
    netappClusterLUNVolumeName=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].location.volume.name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusterLUNOSTYPE=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].os_type")
    netappClusterLUNSerial=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].serial_number")
    netappClusterLUNSpace=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].space.size")
    netappClusterLUNSpaceUsed=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].space.used")
    netappClusterLUNStatus=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].status.state")
    netappClusterLUNMapper=$(echo "$netappClusterLUNUrl" | jq --raw-output ".records[$arraylun].status.mapped")
    
    ##Un-comment the following echo for debugging    
    #echo "netapp_LUN_overview,clustername=$netappClusterName,LUNName=$netappClusterLUNName,LUNstate=$netappClusterLUNStatus,LUNlocation=$netappClusterLUNLocation,volumeName=$netappClusterLUNVolumeName,SVMName=$netappClusterLUNSVMName,LUNOSType=$netappClusterLUNOSTYPE,LUNserial=$netappClusterLUNSerial,LUNmapped=$netappClusterLUNMapper LUNSize=$netappClusterLUNSpace,LUNUsed=$netappClusterLUNSpaceUsed"
    
    ##Comment the Curl while debugging
    echo "Writing netapp_LUN_overview to InfluxDB"
    curl -i -XPOST "$netappInfluxDBURL:$netappInfluxDBPort/write?precision=s&db=$netappInfluxDB" -u "$netappInfluxDBUser:$netappInfluxDBPassword" --data-binary "netapp_LUN_overview,clustername=$netappClusterName,LUNName=$netappClusterLUNName,LUNstate=$netappClusterLUNStatus,LUNlocation=$netappClusterLUNLocation,volumeName=$netappClusterLUNVolumeName,SVMName=$netappClusterLUNSVMName,LUNOSType=$netappClusterLUNOSTYPE,LUNserial=$netappClusterLUNSerial,LUNmapped=$netappClusterLUNMapper LUNSize=$netappClusterLUNSpace,LUNUsed=$netappClusterLUNSpaceUsed"
    
    arraylun=$arraylun+1
done

##
# NetApp ONTAP Shares
##
netappONTAPUrl="https://$netappRestServer/api/protocols/cifs/shares?return_timeout=120&max_records=40&fields=name%2Csvm%2Cpath%2Chome_directory%2Coplocks%2Cvolume%2Caccess_based_enumeration%2Cencryption%2Ccomment%2Cacls"
netappClusterSharesUrl=$(curl -X GET "$netappONTAPUrl" -H "Accept:application/json" -H  "authorization: Basic $netappAuth" -H "Content-Length: 0" 2>&1 -k --silent)

declare -i arrayshares=0
for row in $(echo "$netappClusterSharesUrl" | jq -r '.records[].uuid'); do
    
    netappClusterShareSVMName=$(echo "$netappClusterSharesUrl" | jq --raw-output ".records[$arrayshares].svm.name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusterShareName=$(echo "$netappClusterSharesUrl" | jq --raw-output ".records[$arrayshares].name" | awk '{gsub(/ /,"\\ ");print}')
    netappClusterSharePath=$(echo "$netappClusterSharesUrl" | jq --raw-output ".records[$arrayshares].path"  | awk '{gsub(/ /,"\\ ");print}')
    netappClusterShareEncryption=$(echo "$netappClusterSharesUrl" | jq --raw-output ".records[$arrayshares].encryption")
        case $netappClusterShareEncryption in
            true)
                shareEncryption="1"
            ;;
            false)
                shareEncryption="2"
            ;;
            esac
    netappClusterShareVolumeName=$(echo "$netappClusterSharesUrl" | jq --raw-output ".records[$arrayshares].volume.name")
    
    ##Un-comment the following echo for debugging    
    #echo "netapp_shares_overview,clustername=$netappClusterName,SVMName=$netappClusterShareSVMName,shareName=$netappClusterShareName,sharePath=$netappClusterSharePath,volumeName=$netappClusterShareVolumeName shareEncryption=$shareEncryption"
    
    ##Comment the Curl while debugging
    echo "Writing netapp_cluster_overview to InfluxDB"
    curl -i -XPOST "$netappInfluxDBURL:$netappInfluxDBPort/write?precision=s&db=$netappInfluxDB" -u "$netappInfluxDBUser:$netappInfluxDBPassword" --data-binary "netapp_shares_overview,clustername=$netappClusterName,SVMName=$netappClusterShareSVMName,shareName=$netappClusterShareName,sharePath=$netappClusterSharePath,volumeName=$netappClusterShareVolumeName shareEncryption=$shareEncryption"
    
    arrayshares=$arrayshares+1
done

##
# NetApp ONTAP Cluster Metrics
##
netappONTAPUrl="https://$netappRestServer/api/cluster/metrics?order_by=timestamp%20desc&fields=*&interval=1h&max_records=$netappMetrics"
netappClustermetricsUrl=$(curl -X GET "$netappONTAPUrl" -H "Accept:application/json" -H  "authorization: Basic $netappAuth" -H "Content-Length: 0" 2>&1 -k --silent)

declare -i arraymetrics=0
for row in $(echo "$netappClustermetricsUrl" | jq -r '.records[].timestamp'); do
    
    netappClusterTZ=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].timestamp")
    netappClustertimestamp=$(date -d "$netappClusterTZ" +"%s")
    netappClusterlatencyread=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].latency.read")
    netappClusterlatencywrite=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].latency.write")
    netappClusterlatencyother=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].latency.other")
    netappClusterlatencytotal=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].latency.total")    
    netappClusteriopsread=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].iops.read")
    netappClusteriopswrite=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].iops.write")
    netappClusteriopsother=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].iops.other")
    netappClusteriopstotal=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].iops.total")    
    netappClusterthroughputread=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].throughput.read")
    netappClusterthroughputwrite=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].throughput.write")
    netappClusterthroughputother=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].throughput.other")
    netappClusterthroughputtotal=$(echo "$netappClustermetricsUrl" | jq --raw-output ".records[$arraymetrics].throughput.total")

    ##Un-comment the following echo for debugging
    #echo "netapp_cluster_metrics,clustername=$netappClusterName latencyRead=$netappClusterlatencyread,latencyWrite=$netappClusterlatencywrite,latencyOther=$netappClusterlatencyother,latencyTotal=$netappClusterlatencytotal,iopsRead=$netappClusteriopsread,iopsWrite=$netappClusteriopswrite,iopsOther=$netappClusteriopsother,iopsTotal=$netappClusteriopsread,troughputRead=$netappClusterthroughputread,troughputWrite=$netappClusterthroughputwrite,troughputOther=$netappClusterthroughputother,troughputTotal=$netappClusterthroughputtotal $netappClustertimestamp"
    
    ##Comment the Curl while debugging
    echo "Writing netapp_cluster_metrics to InfluxDB"    
    curl -i -XPOST "$netappInfluxDBURL:$netappInfluxDBPort/write?precision=s&db=$netappInfluxDB" -u "$netappInfluxDBUser:$netappInfluxDBPassword" --data-binary "netapp_cluster_metrics,clustername=$netappClusterName latencyRead=$netappClusterlatencyread,latencyWrite=$netappClusterlatencywrite,latencyOther=$netappClusterlatencyother,latencyTotal=$netappClusterlatencytotal,iopsRead=$netappClusteriopsread,iopsWrite=$netappClusteriopswrite,iopsOther=$netappClusteriopsother,iopsTotal=$netappClusteriopsread,troughputRead=$netappClusterthroughputread,troughputWrite=$netappClusterthroughputwrite,troughputOther=$netappClusterthroughputother,troughputTotal=$netappClusterthroughputtotal $netappClustertimestamp"
    
    arraymetrics=$arraymetrics+1
done