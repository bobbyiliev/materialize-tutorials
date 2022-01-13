<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <title>Laravel EventStream</title>

        <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tailwindcss/dist/tailwind.min.css">

    </head>
    <body>
        <div class="container w-full mx-auto pt-20">
            <div class="w-full px-4 md:px-0 md:mt-8 mb-16 text-gray-800 leading-normal">

                <div class="flex flex-wrap">
                    <div class="w-full md:w-2/2 xl:w-3/3 p-3">
                        <div class="bg-white border rounded shadow p-2">
                            <div class="flex flex-row items-center">
                                <div class="flex-shrink pr-4">
                                    <div class="rounded p-3 bg-green-600"><i class="fa fa-wallet fa-2x fa-fw fa-inverse"></i></div>
                                </div>
                                <div class="flex-1 text-right md:text-center">
                                    <h5 class="font-bold uppercase text-gray-500">Total number of trades</h5>
                                    <h3 class="font-bold text-3xl"> <span id="total">0</span></h3>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="w-full md:w-2/2 xl:w-3/3 p-3">
                        <div class="bg-white border rounded shadow p-2">
                            <div class="flex flex-row items-center">
                                <div class="flex-shrink pr-4">
                                    <div class="rounded p-3 bg-yellow-600"><i class="fas fa-user-plus fa-2x fa-fw fa-inverse"></i></div>
                                </div>
                                <div class="flex-1 text-right md:text-center">
                                    <h5 class="font-bold uppercase text-gray-500">Latest trade</h5>
                                    <h3 class="font-bold text-3xl">
                                        <p>
                                            Name: <span id="latest_trade_user"></span>
                                            Stock: <span id="latest_trade_stock"></span>
                                            Type: <span id="latest_trade_type"></span>
                                            Price: <span id="latest_trade_price"></span>
                                            Volume: <span id="latest_trade_volume"></span>
                                        </p>
                                    </h3>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <hr class="border-b-2 border-gray-400 my-8 mx-4">
                <div class="flex flex-row flex-wrap flex-grow mt-2">
                    <div class="w-full p-3">
                        <div class="bg-white border rounded shadow">
                            <div class="border-b p-3">
                                <h5 class="font-bold uppercase text-gray-600">Table</h5>
                            </div>
                            <div class="p-5 overflow-scroll h-32">
                                <table class="w-full p-5 text-gray-700">
                                    <thead>
                                        <tr>
                                            <th class="text-left text-blue-900">Trades in the last 60 seconds</th>
                                        </tr>
                                    </thead>
                                    <tbody id="allTrades">
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </body>
    <script>
        var eventSourceTail = new EventSource("/tail");

        eventSourceTail.onmessage = function(event) {
            const newElement = document.createElement("tr");
            const eventList = document.getElementById("allTrades");
            newElement.textContent = "message: " + event.data;
            //newElement.textContent = "ping at " + time;
            eventList.prepend(newElement);
        }

        var eventSource = new EventSource("/mz-stream");

        eventSource.onmessage = function(event) {

            const eventTotal = document.getElementById("total");
            // Get the data from the event total trades
            if (event.data.includes('total_trades')) {
                let value = JSON.parse(event.data)

                eventTotal.innerHTML = value.total_trades;
            }

            const latest_trade_user = document.getElementById("latest_trade_user");
            const latest_trade_stock = document.getElementById("latest_trade_stock");
            const latest_trade_type = document.getElementById("latest_trade_type");
            const latest_trade_price = document.getElementById("latest_trade_price");
            const latest_trade_volume = document.getElementById("latest_trade_volume");
            // Get the data from the event latest trades
            if (event.data.includes('latest_trade_user')) {
                let value = JSON.parse(event.data)

                latest_trade_user.innerHTML = value.latest_trade_user;
                latest_trade_stock.innerHTML = value.latest_trade_stock;
                latest_trade_type.innerHTML = value.latest_trade_type;
                latest_trade_price.innerHTML = value.latest_trade_price;
                latest_trade_volume.innerHTML = value.latest_trade_volume;
            }
        }

    </script>
</html>
