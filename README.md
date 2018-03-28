# Photios On Line (PhoOL)

This repository contains the code that runs [Photios On Line](https://dcthree.github.io/photios/), a collaborative translation project for the *Lexicon* of [Photios](https://en.wikipedia.org/wiki/Photios_I_of_Constantinople).

Data is available at: <https://github.com/dcthree/photios-data>

See also:

 * [Harpokration On Line](https://dcthree.github.io/harpokration/)
 * [The Index of Ancient Greek Lexica](https://dcthree.github.io/ancient-greek-lexica/)

## Technical Details

This repository is a fork of <https://github.com/ryanfb/cts-cite-driver> to draw both CTS text and CITE translations from Google Fusion Tables, with additional modifications for linking to the Suda On Line and Perseus for text entries.

The editing links currently point at an instance of the [CITE Collection Editor](https://github.com/ryanfb/cite-collection-editor) proxied by a [CITE Collection Manager](https://github.com/ryanfb/cite-collection-manager) instance running on Google App Engine at <http://cite-harpokration.appspot.com/>.
