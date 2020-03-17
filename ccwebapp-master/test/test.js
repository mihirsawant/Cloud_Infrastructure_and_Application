
const chai = require('chai');
const chaiHttp = require('chai-http');
const server=require("../app");
var assert = require("assert");
const should = chai.should();
const moment = require('moment');
moment().format();
chai.use(chaiHttp);





describe ("Email Validation", function(){

    var users = {
        "firtsname": "Priyal",
        "lastname": "Shrotriya",
        "email_address":"ps",
        "password":"Priyal@1"

    }
    it("it should not create a user with invalid email address", (done) => {
        for (user in users) {
            chai.request(server)
                .get("/users")
                .send(users[user])
                .end((err, res) => {
                    res.should.have.status(200);
                    console.log("Testing Response Body:", res.body);
                    res.users.should.have.property('errors');
                    res.users.errors.email_address.should.have.property('kind').eql('required');
                    done();
                });
        }
       
    })
   
})


