# Learn More About Metering SAP HANA Cloud

The **Easy Franchise application** does not store a large amount of data, nor are the SQL statements long-running or frequently-executed.

Your scenario might differ here. 

In case you would like to measure the used memory the monitoring view [M_CS_TABLES](https://help.sap.com/viewer/4fe29514fd584807ac9f2a04f6754767/2.0.01/en-US/20ad60f77519101498ccb610c33c3ca6.html) which provides runtime data for a column table might help. The disadvantage is that this monitoring view only provides values for a timestamp. If your amount of data differs over the time, you should consider counting the Create/Update/Read/Delete operations.

In case your application produces big workload, you can use **Workload Classes** to restrict the workload. To learn more, see [Managing Workload with Workload Classes](https://help.sap.com/viewer/6a504812672d48ba865f4f4b268a881e/Cloud/en-US/5066181717df4110931271d1efd84cbc.html) at SAP Help Portal.
