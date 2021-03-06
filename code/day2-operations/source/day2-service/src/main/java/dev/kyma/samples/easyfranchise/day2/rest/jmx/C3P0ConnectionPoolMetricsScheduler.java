/**
 * This class implement a springboot scheduler to retrieve C3P0 database pool metrics via JMX. 
 * For more details refer to https://www.mchange.com/projects/c3p0/ 
 * 
 * The class is initialized by Springboot with JMX server host and port. They are defined in application.properties file.
 */
package dev.kyma.samples.easyfranchise.day2.rest.jmx;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
public class C3P0ConnectionPoolMetricsScheduler {

  private static final Logger logger = LoggerFactory.getLogger(C3P0ConnectionPoolMetricsScheduler.class);

  private JmxMBeanClientInterface attributeClient; 

  @Value("${jmx.local.run}")
  private boolean localRun;

  // read propertie from application.properties file.
  public C3P0ConnectionPoolMetricsScheduler(@Value("${jmx.remote.host}") String remoteHost, @Value("${jmx.remote.port}") int remotePort) {

    this.attributeClient = new JmxMBeanClient(remoteHost, remotePort);

    C3P0GaugeController.createSingletonInstance();
  }

  @Scheduled(fixedRateString = "5000", initialDelayString = "0")
  public void schedulingTask() {

    if(localRun){
      logger.info("day2-service runs locally, no metrics available");
    }else {
      logger.info("day2-service schedulingTask get called, updating metrics");
      C3P0GaugeController.retrieveMetrics(attributeClient);  
    }
  }

}
