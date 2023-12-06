# Learn More About Other Business Logic Metrics

When looking at the **Easy Franchise Application**, you might want to meter other metrics. For example, you might want to count when an email is sent or when a new mentor is assigned. 

In your own scenario you might face completely different requirements. 

For all of those, you can use a similar approach as we showed for the **active users**.
Just add the required logic to your Java services and provide your meetering information to the Day2 service which can persist the information in the respective database table of the  **Metering Database Schema**. Provide a new fitting new REST endpoint to the Day2 service to replay your metering data, which can be called by the UI.

## Result
You are able to transfer the concept of metering to your own business case.
