<h1>Bienvenidos! Esta es mi configuracion de NVim</h1>

Utilizo plugins como Deoplete, NeoSnippet, NerdTree, entre otros.

Cualquier consejo, sugerencia, etc... es mas que bienvenida a traves de los Issues.

Para instalarlo es necesario hacer lo siguiente:

Escribir en la terminal:

Clonate el proyecto:
<pre>git clone https://github.com/brianfiszman/dofiles</pre>

Entrá a la carpeta del proyecto: `cd ./dotfiles`

<pre>
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
sh ./installer.sh ~/.cache/dein
</pre>

Luego copiar la carpeta .config/nvim en tu ~/.config/ de tu usuario.

Escribir en el NVim:

<pre>:call dein#install()</pre>

**Los siguientes dotfiles los utilizo en ArchLinux**
