A service for hosting a private Docker Registry

|                 |   |
| --------------- | - |
| Virtual Machine | x |
| Kubernetes      |   |

<table>
<tbody>
<tr class="odd">
<td><p>Update</p></td>
<td><p>Automatically on restart</p></td>
</tr>
<tr class="even">
<td><p>Restart</p></td>
<td><p>Ssh to the virtual machine<br />
Run <code>sudo systemctl restart harbor</code></p></td>
</tr>
<tr class="odd">
<td><p>Installation Directory</p></td>
<td><p>/opt/harbor</p></td>
</tr>
<tr class="even">
<td><p>Authentication</p></td>
<td><p>Connected to Keycloak</p></td>
</tr>
</tbody>
</table>

|         |                                     |
| ------- | ----------------------------------- |
| Website | <https://registry.cloud.cbh.kth.se> |

<table>
<tbody>
<tr class="odd">
<td><p>Persistent Data</p></td>
<td><p>/data<br />
nfs share</p></td>
</tr>
</tbody>
</table>