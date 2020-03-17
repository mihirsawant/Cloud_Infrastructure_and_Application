
const chai = require('chai');
const chaiHttp = require('chai-http');
const app=require("../../app");

const users=require("./api/routes/users");
const users=require("./")


const should = chai.should;

const moment = require('moment');
moment().format();


chai.use(chaiHttp);

// describe('Create new User', () => {
//     it('Create new  User', (done) => {
//         const user = {
//             email_address: "s@gmail.com",
//             password: "Mihir@12"
//         }
//         chai.request('http://localhost:3000')
//             .post('/')
//             .send(user)
//             .end((err, res) => {
//                 expect(res.status).to.equal(200);
//                 done();
//             })
//     })
// });



describe('Create new User', () => {
    it('Create new  User', (done) => {
        const users = {
            firtsname: "Priyal",
            lastname: "Shrotriya",
            email_address:"ps@gmail.com",
            password:"Priyal@1"
        };
        chai.request('server')
            .post('/')
            .send(users)
            .end((err, res) => {
                res.should.have.status('200');
                res.body.should.be.a('object');
                res.body.should.have.property('message').eql('User successfully created');
                res.body.user.should.have.property('firtsname');
                res.body.user.should.have.property('lastname');
                res.body.user.should.have.property('email_address');
                res.body.user.should.have.property('password');
                done();
            });
    });
});




// describe('Get Users', () => {
//     it('Get Users status code as success', (done) => {

//         const time = moment().format();
//         chai.request(server)
//             .get('/self')
//             .set('Authorization', 'Basic dEBnbWFpbC5jb206VGVqYXNAMTE=')
//             .end((err, res) => {
//                 res.should.have.status(200);
//                 done();
//             });
//     });
// });


// describe('Create a reciepe', () => {
//     it('Post reciepe status code as success', (done) => {
//         const reciepe = {
        
//             cook_time_in_min : "15",
//             prep_time_in_min : "15",
//             title : "Pav Bhaji",
//             cusine : "Indian",
//             servings : 4,
//             ingredients: "3 tablespoons butter",
//             steps: [
//                 {
//                   position: 2,
//                   items: "veggies"
//                 }
//               ],
//               nutrition_information: {
//                 calories: 250,
//                 cholesterol_in_mg: 3,
//                 sodium_in_mg: 150,
//                 carbohydrates_in_grams: 50.7,
//                 protein_in_grams: 40.7
//               }
            
//         }
//         chai.request(server)
//             .post('/')
//             .set('Authorization', 'EBnbWFpbC5jb206VGVqYXNAMTE=')
//             .send(reciepe)
//             .end((err, res) => {
//                 res.should.have.status(200);
//                 done();
//             });
//     });
// });

module.exports=router;