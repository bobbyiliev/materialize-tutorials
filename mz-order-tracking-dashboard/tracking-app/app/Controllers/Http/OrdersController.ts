import Database from '@ioc:Adonis/Lucid/Database'
import Order from 'App/Models/Order'
import Coordinate from 'App/Models/Coordinate'
const { Kafka } = require('kafkajs')

export default class OrdersController {

    public async index({view}) {

        let status = 0;

        const order = await Order.query().orderBy('id', 'desc').first();
        if (order) {
            status = order.status;
        }
        return view.render('index', {
            status: status
        });

    }

    // Event Stream to get the order status as it changes
    public async stream({response}){
        // First we set a header to identify that this would be an event stream
        response.response.setHeader('Content-Type',  'text/event-stream');

        // Define Database connection
        const materialize = Database.connection('materialize');

        // Then we declare a TAIL cursor
        await materialize.rawQuery('BEGIN');
        await materialize.rawQuery('DECLARE orders_c CURSOR FOR TAIL last_order_with_coordinates');
        // Finally we use FETCH in a loop to retrieve each batch of results as soon as it is ready
        while (true) {
            const res = await materialize.rawQuery('FETCH ALL orders_c');
            response.response.write(`data: ${JSON.stringify(res.rows)}\n\n`)
        }
    }

    public async order({request, response}){
        // Insert the new order in Postgres
        const order = new Order();
        order.status = 1;
        order.user_id = 1;
        order.created_at = new Date();
        await order.save();

        await new Promise(resolve => setTimeout(resolve, 4000));
        order.status = 2;
        await order.save();

        await new Promise(resolve => setTimeout(resolve, 4000));
        order.status = 3;
        await order.save();

        // Start the delivery tracking
        await this.delivery(order.id);

        await new Promise(resolve => setTimeout(resolve, 4000));
        order.status = 4;
        await order.save();

    }

    public async delivery(order_id){
        // Initial driver location
        let driver_lat = 116.51972;
        let driver_lng = 39.51972;

        // Customer location Coordinate from Postgres
        const coordinates = await Coordinate.query().where('user_id', 1).first();

        let distance = calcCrow(driver_lat, driver_lng, coordinates.latitude, coordinates.longitude).toFixed(1);
        // Reduce the distance by 10% by changing the driver coordinates until the distance is less than 10 meters
        while (distance > 0.01) {
            console.log(`Driver is ${distance} km away from customer`);
            await new Promise(resolve => setTimeout(resolve, 500));
            // Update driver coordinates to get closer to the customer
            driver_lat = driver_lat + 0.0001;
            driver_lng = driver_lng + 0.0001;
            // Calculate distance between driver and customer
            distance = calcCrow(driver_lat, driver_lng, coordinates.latitude, coordinates.longitude).toFixed(1);

            // Store the coordinates in Kafka/Redpanda
            await this.track(order_id, driver_lat, driver_lng, distance);
        }
        // Order will be delivered anytime now
        console.log('Order is delivered');
    }

    // Store the coordinates of the driver in Kafka
    public async track(order_id, latitude, longitude, distance){
        // Create a Kafka client
        const kafka = new Kafka({
            clientId: 'tracking-app',
            brokers: ['redpanda:9092'],
        })
        console.log(order_id)
        // Create a producer
        const producer = kafka.producer()
        // Wait for the ready event
        await producer.connect()
        await producer.send({
            topic: 'coordinates',
            messages: [
                { value: JSON.stringify({
                    user_id: 1,
                    order_id: order_id,
                    latitude: latitude,
                    longitude: longitude,
                    distance: distance,
                    timestamp: new Date()
                })},
            ],
        })
        // Close the producer
        await producer.disconnect()
    }

    function calcCrow(lat1, lon1, lat2, lon2)
    {
        var R = 6371; // km
        var dLat = toRad(lat2-lat1);
        var dLon = toRad(lon2-lon1);
        var lat1 = toRad(lat1);
        var lat2 = toRad(lat2);

        var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        var d = R * c;
        return d;
    }

    // Converts numeric degrees to radians
    function toRad(Value)
    {
        return Value * Math.PI / 180;
    }

}
