#!/usr/bin/env php
<?php

require "./vendor/autoload.php";

use Amp\Http\Server\RequestHandler\CallableRequestHandler;
use Amp\Http\Server\HttpServer;
use Amp\Http\Server\Request;
use Amp\Http\Server\Response;
use Amp\Http\Status;
use Amp\Socket\Server;
use Psr\Log\NullLogger;

// Run this script, then visit http://localhost:80/ in your browser.

Amp\Loop::run(function () {
    $sockets = [
        Server::listen("0.0.0.0:80"),
        Server::listen("[::]:80"),
    ];

    $server = new HttpServer($sockets, new CallableRequestHandler(function (Request $request) {
        return new Response(Status::OK, [
            "content-type" => "text/plain; charset=utf-8"
        ], "Hello, World!");
    }), new NullLogger);

    yield $server->start();

    // Stop the server gracefully when SIGINT is received.
    // This is technically optional, but it is best to call Server::stop().
    Amp\Loop::onSignal(SIGINT, function (string $watcherId) use ($server) {
        Amp\Loop::cancel($watcherId);
        yield $server->stop();
    });
});
