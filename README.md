<h1>Bienvenidos! Esta es mi configuracion de NVim</h1>

Utilizo plugins como YouCompleteMe, UltiSnips, NerdTree, entre otros.

Cualquier consejo, sugerencia, etc... es mas que bienvenida a traves de los Issues.

Para instalarlo es necesario hacer lo siguiente:

Escribir en la terminal:

Clonate el proyecto:
<pre>git clone https://github.com/brianezequielfiszman/dofiles</pre>

Entrá a la carpeta del proyecto: `cd ./dotfiles`

<pre>
git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim
</pre>



Luego copiar el .vimrc en tu home de usuario o escribir en la carpeta del proyecto

<pre>cp .vimrc ~/.config/nvim/init.vim</pre>

Escribir en la linea de comandos lo siguiente:

<pre>nvim +PluginInstall +qall</pre>

Una vez instalado todo vas a querer funciones de autocompletado, para eso queremos instalar el YouCompleteMe,(el plugin se instala pero no viene preconfigurado para su uso)

Para configurar el YouCompleteMe se necesita instalarlo manualmente siguiendo la documentacion de su developer, 
pero mi manera de hacerlo es la siguiente: 
(AVISO: Se necesita tener instalado un interprete de Python)<br>
<pre>~/.config/nvim/bundle/YouCompleteMe/install.py --all</pre>

El proceso de compilado es largo, CUIDADO a los que tengan 4GB de RAM o menos, el proceso de compilado es muy pesado y te puede enlentecer la PC al punto de no tener otra opcion que reiniciarla.

Para este tipo de casos es muy recomendable usar una particion SWAP

Otra cosa a tener en cuenta es la configuracion del archivo .ycm_extra_conf.py, incluí mi propio archivo en el proyecto, pero pueden extenderlo o cambiarlo a medida.

De querer usar el mio solo copien el .ycm_extra_conf.py que incluí en la carpeta del proyecto en 
<pre>~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py</pre>


**Los siguientes dotfiles los utilizo en ArchLinux**