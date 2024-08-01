---
title:  Script to Create Switch Configs
date:   2012-10-19 00:00:00 -0500
categories: IT
---

I had a big stack of switches of various different models that needed configuration. The first thought was that I could create a spreadsheet with information for each switch and then use a script to create the configs.

The attached script and spreadsheet placed in the root of the C:\ (anywhere else and you'll have to change some paths) will create one text file per device.

This script can use a lot of work yet, but it's enough to give you a start. You can add in best practice configs and your own standards for an individual environment.

Have multiple configs? Add a column to the spreadsheet and put an "if, then, else" in the script to select the appropriate settings.

<table>
<tr><td>
<p style="color:orange">**** NOTE ****
</td></tr>
<tr><td>

This script currently only creates configs for a handful of devices. However, you can change or add devices pretty easily.

</td></tr>
</table>

<table>
<tr><td>
<p style="color:red">******WARNING******
</td></tr>
<tr><td>

***DO NOT*** use this config on any production switches. There is litttle security involved here. This is the config I had to use, but wouldn't recomend this config to someone I don't even like very much.
</td></tr>
</table>

Ideally, I would like to add as many of the currently supported switches and wrap this script in an HTA.

To be continued....
