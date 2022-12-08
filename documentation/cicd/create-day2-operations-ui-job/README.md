# Create a Job for Day 2 Operations UI

The second job which will build the day 2 UI works almost the same as the EasyFranchise UI. So you can follow the [previous description](../create-easyfranchise-ui-job/README.md) with the following differences:

## Configure "Staging" in the Continuous Integration and Delivery Job

* Configure the **General Parameters**: Use day2-ui-001 as a tag
* Configure the **Build**: Use /code/day2-operations/deployment/docker/Dockerfile-day2-ui as path
* Configure the acceptance and release stages:
  * **Kubernetes Credentials**: choose the service account credentials created for the day2-operations namespace
  * **Namespace**: day2-operations
  * **Deploy Tool**: helm3
  * **Chart Path**: ./code/day2-operations/deployment/helmCharts/day2-ui-chart
  * **Deployment Name**: day2-ui
