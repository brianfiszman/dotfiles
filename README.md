<h1>Welcome to my Dotfiles!</h1>

<h2>Install</h2>
<pre>
$ git clone https://github.com/brianfiszman/dotfiles
$ cd ./dotfiles
$ sudo chmod +x ./install.sh
</pre></br>

Now run the `install.sh` script.

<pre>$ sh ./install.sh</pre></br>

Okey, for Emacs just open Emacs and the configuration will be installed by itself.

As for NeoVim, open `nvim` and input the following:

<pre>:call dein#install()</pre>
</br>
That's it, enjoy!
