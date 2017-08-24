/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

window.addEventListener('cloudkitloaded', function() {
  console.log("listening for cloudkitloaded");
  CloudKit.configure({
    containers: [{
      containerIdentifier: 'iCloud.com.GoeAdventure.Goe',
        apiTokenAuth: {
            apiToken: '1934b95597d2ddbac825cbd5b72958c26b68d430ce014a44001abe23e32429d8',
            persist: true
        },
      environment: 'development'
    }]
  });
  console.log("cloudkitloaded");
                        
  function TILViewModel() {
    var self = this;
    console.log("get default container");
    var container = CloudKit.getDefaultContainer();

    console.log("setting publicDB");
    var publicDB = container.publicCloudDatabase;
    self.items = ko.observableArray();

    self.fetchRecords = function() {
          console.log("Fetching records from " + publicDB);
          var query = { recordType: "Adventure", sortBy: [{fieldName: "Start_Date"}]};

          return publicDB.performQuery(query).then(function(response) {
              if (response.hasErrors) {
                  console.error(response.errors[0]);
                  return;
              }
              var records = response.records;
              var numberOfRecords = records.length;
              if (numberOfRecords === 0) {
                  console.log("No matching items");
                  return;
              }
              for (index = 0; index < numberOfRecords; index++) {
                  console.log(records[index])
              }
              self.items(records);
          });
      };
      self.newAdventure = ko.observable('');
      self.newCategory = ko.observable('');
      self.saveButtonEnabled = ko.observable(true);
      self.newItemVisible = ko.observable(false);

      self.saveNewAdventure = function() {
          if (self.newAdventure().length > 0 && self.newCategory().length > 0) {
              self.saveButtonEnabled(false);
              var record = {recordType: "Adventure",
                fields: {Name: {value: self.newAdventure() },
                Category: {value: self.newCategory() }}
              };
              publicDB.saveRecord(record).then(function(response) {
                  if (response.hasErrors) {
                      console.error(response.errors[0]);
                      self.saveButtonEnabled(true);
                      return;
                  }
                  var createdRecord = response.records[0];
                  self.items.push(createdRecord);
                  self.newAdventure("");
                  self.newCategory("");
                  self.saveButtonEnabled(true);
              });
          } else {
              alert("Adventures must have a name and a category");
          }
      };

      self.displayUserName = ko.observable('Unauthenticated User');
      self.gotoAuthenticatedState = function(userInfo) {
          self.newItemVisible(true);
          if(userInfo.isDiscoverable) {
              self.displayUserName(userInfo.firstName + ' ' + userInfo.lastName);
          } else {
              self.displayUserName('User Who Must Not Be Named');
          }

          container
              .whenUserSignsOut()
              .then(self.gotoUnauthenticatedState);
      };

      self.gotoUnauthenticatedState = function(error) {
          self.newItemVisible(false);
          self.displayUserName('Unauthenticated User');

          container
              .whenUserSignsIn()
              .then(self.gotoAuthenticatedState)
              .catch(self.gotoUnauthenticatedState);
      };

      container.setUpAuth().then(function(userInfo) {
          console.log("setUpAuth");
          self.fetchRecords()
          if(userInfo) {
              self.gotoAuthenticatedState(userInfo);
          } else {
              self.gotoUnauthenticatedState();
          }
      })
  }
  
  ko.applyBindings(new TILViewModel());
});
