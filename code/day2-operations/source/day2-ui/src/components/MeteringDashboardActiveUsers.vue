<template> 
  <div>
    <h2>Active Users per Tenant</h2>
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
      <fd-table :headers="[{ label: 'Tenant ID', key: 'tenantid', sortable: true, sortBy: `tenantid`}, { label: 'Active Users', key: 'activeUsers', sortable: true, sortBy: `activeUsers`}]" :items="activeUsers" class="mb-5">
        <template #row="{ item }">
          <fd-table-row>
            <template #Tenant ID>
              <fd-table-cell>
                {{ item.tenantid }}
              </fd-table-cell>
            </template>
            <template #Active Users>
              <fd-table-cell>
                {{ item.activeUsers }}
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
  name: 'MeteringDashboardActiveUsers',
  props: [],
  data: function(){
    return {
      actualMonth: "",
      actualYear: "",
      activeUsers: []
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
    loadActiveUsers() {
      console.log("Starting loading active users...");
      console.log("Requested month: " + this.actualMonth);
      console.log("Requested year: " + this.actualYear);
      const apiUrl = this.$backendApi + "/metric?year=" + this.actualYear + "&month=" + this.actualMonth;
      fetch(apiUrl)
      .then(response => response.json())
      .then(data => {
        this.activeUsers = data;
        console.log("[DEBUG] ActiveUsers loaded: ", data);
      });
    },
    updateData() {
      console.log("Update triggered");
      this.loadActiveUsers();
    }
  },
 mounted: function(){
   this.getActualPeriod();
   this.loadActiveUsers();
  }
}
</script>

<style>

</style>