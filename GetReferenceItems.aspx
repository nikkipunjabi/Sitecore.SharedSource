<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.Links" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Get Reference Items</title>

    <style>
        body {
            font-family: verdana, arial, sans-serif;
        }

        table.table-style-three {
            font-family: verdana, arial, sans-serif;
            font-size: 11px;
            color: #333333;
            border-width: 1px;
            border-color: #3A3A3A;
            border-collapse: collapse;
        }

            table.table-style-three th {
                border-width: 1px;
                padding: 8px;
                border-style: solid;
                border-color: #FFA6A6;
                background-color: #D56A6A;
                color: #ffffff;
            }

            table.table-style-three tr:hover td {
                cursor: pointer;
            }

            table.table-style-three tr:nth-child(even) td {
                background-color: #F7CFCF;
            }

            table.table-style-three td {
                border-width: 1px;
                padding: 8px;
                border-style: solid;
                border-color: #FFA6A6;
                background-color: #ffffff;
            }
    </style>
    <script language="CS" runat="server"> 

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAuthenticated == false)
            {
                Response.Redirect("login.aspx?returnUrl=UnlockItem.aspx");
            }
        }

        protected void getReferenceItems_Click(object sender, EventArgs e)
        {
            int i = 0;
            try
            {
                Database db = Database.GetDatabase("master");
                Item item = db.GetItem(txtID.Text);
                if (item != null)
                {
                    //This will return Standard Values as well!
                    var links = Globals.LinkDatabase.GetReferrers(item);
                    if (links != null)
                    {
                        var linkedItems = links.Select(ii => ii.GetSourceItem()).Where(ii => ii != null);
                        var paths = linkedItems.Select(ii => ii.Paths.FullPath);

                        var itemLinksPath = paths;
                        i = itemLinksPath.Count();
                        lblMessage.Text += "ItemPaths:<br>";
                        lblMessage.Text += string.Join("<br>", itemLinksPath.ToArray());
                        lblMessage.Text += "<br><br>ItemIDs:<br>";
                        lblMessage.Text += string.Join("<br>", linkedItems.Select(ii => ii.ID.ToString()).ToArray());
                        return;
                    }
                }
                if (i == 0)
                {
                    lblMessage.Text = "Locked total " + i + " item(s)";
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = ex.ToString();
            }
        }

    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Get Reference Items of an Item</h2>
        <table class="table-style-three">
            <tr>
                <td colspan="2" style="vertical-align: top">Give Me Item ID or Path:
                    <asp:TextBox ID="txtID" Width="400px" runat="server"></asp:TextBox></td>
                <td style="vertical-align: top"></td>
            </tr>
            <tr>
                <td>
                    <asp:Button ID="btnGetReferenceItems" runat="server" Text="Get Reference Items" OnClick="getReferenceItems_Click" /></td>
                <td colspan="2"></td>
            </tr>
            <tr>
                <td colspan="3">
                    <asp:Label ID="lblMessage" runat="server"></asp:Label>
                </td>
            </tr>
        </table>
    </form>
</body>
</html>
