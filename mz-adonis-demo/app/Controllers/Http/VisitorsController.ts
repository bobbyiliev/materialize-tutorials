// import { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import Database from '@ioc:Adonis/Lucid/Database'

export default class VisitorsController {

    public async source({request, response}) {

        //Using Ludic to connect to Materialize, we are executing a CREATE SOURCE query
        const res = await Database.rawQuery(
            `CREATE SOURCE requests
                FROM FILE '/log/requests' WITH (tail = true)
                FORMAT REGEX '(\\?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - - \[(\\?P<ts>[^]]+)\] "(\\?P<path>(\\?:GET /search/\\\?kw=(\\?P<search_kw>[^ ]*) HTTP/\d\.\d)|(\\?:GET /detail/(\\?P<product_detail_id>[a-zA-Z0-9]+) HTTP/\d\.\d)|(\\?:[^"]+))" (\\?P<code>\d{3}) -';`
            );
        return res;

    }

    public async view({request, response}) {

        //Using Ludic to connect to Materialize, we are executing a CREATE VIEW statement
        const res = await Database.rawQuery(
            `CREATE MATERIALIZED VIEW unique_visitors AS
                SELECT count(DISTINCT ip) FROM requests;`
            );
        return res;

    }

    public async visitors({request, response}) {

        // First we set a header to identify that this would be an event stream
        response.response.setHeader('Content-Type',  'text/event-stream');

        // Then we declare a TAIL cursor
        await Database.rawQuery('BEGIN');
        await Database.rawQuery('DECLARE visitors_c CURSOR FOR TAIL unique_visitors');

        // Finally we use FETCH in a loop to retrieve each batch of results as soon as it is ready
        while (true) {
            const res = await Database.rawQuery('FETCH ALL visitors_c');
            response.response.write(`data: ${JSON.stringify(res.rows)}\n\n`)
        }

    }

    public async index({request,response,view})
    {
        return view.render('visitors')
    }

}