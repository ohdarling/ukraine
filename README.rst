ukraine
=========

``ukraine`` glues ``haibu`` and ``node-http-proxy`` adding a little helper, ``chernobyl``, that deploys into this cloud. It is probably as stable as you think it is.

.. image:: https://raw.github.com/radekstepan/ukraine/master/example.png

Quick start
-----------

Make sure you have ``node >= 0.8.0`` `installed <https://github.com/joyent/node/blob/master/README.md#to-build>`_, 0.8.15 is recommended as current stable.

Install the package globally:

.. code-block:: bash

    $ sudo npm install -g git://github.com/ohdarling/ukraine.git\#private-cloud

Create a ``config.json`` file if not present already in the lib's root:

.. code-block:: json

    {
        "haibu_port": 9002,
        "haibu_listen_ip": "127.0.0.1",
        "proxy_port": 8000,
        "proxy_listen_ip": "127.0.0.1",
        "proxy_host": "127.0.0.1",
        "proxy_hostname_only": false,
        "omit_haibu_port_when_hostname_only": false,
        "auth_token": ""
    }

haibu_port
    On which port to start the Haibu service.
haibu_listen_ip
    On which ip to start the Haibu service, if use nginx as frontend this should be 127.0.0.1
proxy_port
    Where will all requests go? If set to ``80``, you will be able to access your apps without providing a port number.
proxy_listen_ip
    Proxy listen to which ip, if use nginx as frontend, it should be 127.0.0.1
proxy_host
    What is the host used in the proxy routing table. This is the 'domain' you will be using to access the running apps.
auth_token
    A token that a client will need to use to access the ukraine service. Leaving this property out will not require you to pass a token and is useful for debugging.
proxy_hostname_only
    If set to ``true`` your apps will be routed from ``<app_name>.<proxy_host>:<proxy_port>`` instead of ``<proxy_host>:<proxy_port>/<app_name>/``. Useful also in a case when you have links in your app that are root relative.
omit_haibu_port_when_hostname_only
    If use nginx as frontend, and nginx listen to port 80, this should be true, or route in http-proxy table will contain a port and cannot match url without a port

As a server
~~~~~~~~~~~

Start it up:

.. code-block:: bash

    $ bin/ukraine

.. note::
    In order to run the server in the background, I recommend you install `forever.js <https://github.com/nodejitsu/forever>`_ and start the service as follows:

    .. code-block:: bash

        $ sudo npm install forever -g
        $ forever start bin/ukraine
        
On Ubuntu or Debian, there is an init script to start ukraine as a service, see ``server/init-script``, see `INSTALL.md <https://github.com/ohdarling/ukraine/blob/private-cloud/server/INSTALL.md>`_ for detail.

As a client
~~~~~~~~~~~

Move to a directory with the app to deploy. Deploy pointing to cloud instance:

.. code-block:: bash

    $ chernobyl deploy <ukraine_ip>

Config
-----------

For setting environment variables exposed through ``process.env``, set the key value pair ``env`` in your app's ``package.json`` file. You can also use the ``chernobyl`` app itself to pass them if you do not want to expose them in a public ``package.json`` file.

Architecture
------------

ukraine
    Spawns a ``node-http-proxy`` server that dynamically watches for changes in a routing table. All (useful) routes to ``haibu`` have been overwritten using promises.
    
    New method for posting env vars has been added.

    Token authentication per ukraine instance has been added too.

chernobyl
    #. checks that your app's `package.json` file is in order
    #. checks that ``ukraine`` instance is up
    #. check if we need to auth to deploy an app
    #. checks and stops an existing app if need be
    #. packs the new app and sends it to the cloud to deploy

Troubleshooting
---------------

Haibu is a poorly written piece of software, be aware of these facts:

#. If you intend to use the API haibu exposes, be sure to send correct parameters in the right format, otherwise you will shut down the app.
#. Your ``package.json`` start script can only include a file name, not a bash command! Haibu checks that whatever you put in there is an existing file. Even more annoyingly, the file needs to be a js file that node can call.
#. Sometimes zlib complains when streaming a package, the code here attempts to keep packing and streaming apps to deploy if it gets these errors.
#. Uploading a new version of the app would not necessarily invalidate the old version, thus we brutforce remove the previous apps.
#. When an app is deployed, it might still take a second or two for it to actually show over the proxy server.
#. Although it should be allowed, haibu only allows to kill an app by its name, not name and username so we all deploy apps into a ``chernobyl`` namespace and if you want to deploy the same app again on a different port, you need to change its ``name`` in ``config.json``.
#. Restarting the app does not work as one would expect getting the latest env variables, stopping does not either expecting an ``application`` object instead of the ``name`` it is passed from the service. When setting new environment variable, then, we take a custom approach of stopping a running instance, getting the latest hash of its package and starting it again with these settings.

That is why we use our own version of it since `v0.12.0`