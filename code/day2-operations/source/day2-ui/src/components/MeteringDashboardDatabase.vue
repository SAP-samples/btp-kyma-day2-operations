<template> 
  <div>
    <h2>Database size per Tenant</h2>
    <p>This section is just a placeholder using mockdata to demonstrate how a metering Dashboard could looks like.</p>
    <div class="row mb-4"> 
      <div class="col col-lg-2">
        <fd-field-set>
          <fd-form-item>
            <fd-form-label>Selected month</fd-form-label>
            <fd-select v-model="actualMonth" @update="updateData()">
              <option value="01">January</option>
              <option value="02">February</option>
              <option value="03">March</option>
              <option value="04">April</option>
              <option value="05">May</option>
              <option value="06">June</option>
              <option value="07">July</option>
              <option value="08">August</option>
              <option value="09">September</option>
              <option value="10">October</option>
              <option value="11">November</option>
              <option value="12">December</option>
              <option value="green">Green</option>
            </fd-select>
          </fd-form-item>
        </fd-field-set>
      </div>

      <div class="col col-lg-2">
        <fd-field-set>
          <fd-form-item>
            <fd-form-label>Selected year</fd-form-label>
            <fd-select v-model="actualYear" @update="updateData()">
              <option value="2021">2021</option>
              <option value="2022">2022</option>
              <option value="2023">2023</option>
            </fd-select>
          </fd-form-item>
        </fd-field-set>
      </div>
    </div>     

    <div class="row mb-4">
      <fd-table :headers="[{ label: 'Tenant ID', key: 'TENANTID', sortable: true, sortBy: `TENANTID`}, { label: 'Database Consumption', key: 'ACTIVEUSERS', sortable: true, sortBy: `ACTIVEUSERS`}]" :items="databaseDetails" class="mb-5">
        <template #row="{ item }">
          <fd-table-row>
            <template #Tenant ID>
              <fd-table-cell>
                {{ item.TENANTID }}
              </fd-table-cell>
            </template>
            <template #Active Users>
              <fd-table-cell>
                {{ item.ACTIVEUSERS }}
              </fd-table-cell>
            </template>
          </fd-table-row>
        </template>
      </fd-table>
    </div> 
  </div>  
</template>

<script>


export default {
  name: 'MeteringDashboardDatabase',
  props: [],
  data: function(){
    return {
      actualMonth: "",
      actualYear: "",
      databaseDetails: []
    }
  },
  methods: {
    // Get actual month and year
    getActualPeriod(){
      let dateObj = new Date();
      let month = ('0' + (dateObj.getUTCMonth() + 1)).slice(-2); 
      let year = dateObj.getUTCFullYear();
      console.log("Month: " + month);
      this.actualMonth = month;
      this.actualYear = year;
    },
    // Loading active users from backend
    loadDatabaseDetails() {
      console.log("Starting loading Database Details...");
      console.log("Requested month: " + this.actualMonth);
      console.log("Requested year: " + this.actualYear);
      const apiUrl = this.$backendApi + "?year=" + this.actualYear + "&month=" + this.actualMonth;
      fetch(apiUrl)
      .then(response => response.json())
      .then(data => {
        this.databaseDetails = data;
        console.log("[DEBUG] DatabaseDetails loaded: ", data);
      });
    },
    updateData() {
      console.log("Update triggered");
      this.loadDatabaseDetails();
    }
  },
 mounted: function(){
   this.getActualPeriod();
   this.loadDatabaseDetails();
  }
}
</script>

<style>

</style>