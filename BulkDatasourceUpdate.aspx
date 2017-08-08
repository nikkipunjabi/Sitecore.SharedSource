<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="Sitecore.Data" %>
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
    <title>Bulk Datasource Update Tool</title>
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
                Response.Redirect("login.aspx?returnUrl=bulkdatasourceupdate.aspx");
            }
        }

        private void UpdateRenderingDatasource(Item item, string renderingId, string newDatasourceId, ref StringBuilder sbSummary)
        {

            if (item != null)
            {
                //Get all added renderings
                //Sitecore.Layouts.RenderingReference[] renderings = item.Visualization.GetRenderings(Sitecore.Context.Device, true);
                var db = item.Database;
                // Default device from Sitecore
                var deviceItem = db.GetItem("{FE5D7FDF-89C0-4D99-9AA3-B5FBD009C9F3}");
                DeviceItem device = new DeviceItem(deviceItem);

                Sitecore.Layouts.RenderingReference[] renderings = item.Visualization.GetRenderings(device, true).Where(r => r.RenderingID == Sitecore.Data.ID.Parse(renderingId)).ToArray();

                if (renderings.Count() == 0)
                {
                    sbSummary.AppendLine("Rendering not found!");
                }

                // Get the layout definitions and the device
                Sitecore.Data.Fields.LayoutField layoutField = new Sitecore.Data.Fields.LayoutField(item.Fields[Sitecore.FieldIDs.LayoutField]);

                if (!string.IsNullOrEmpty(layoutField.Value))
                {
                    Sitecore.Layouts.LayoutDefinition layoutDefinition = Sitecore.Layouts.LayoutDefinition.Parse(layoutField.Value);

                    Sitecore.Layouts.DeviceDefinition deviceDefinition = layoutDefinition.GetDevice(device.ID.ToString());

                    foreach (Sitecore.Layouts.RenderingReference rendering in renderings)
                    {
                        // Update the renderings datasource value accordingly 
                        deviceDefinition.GetRendering(rendering.RenderingID.ToString()).Datasource = newDatasourceId;
                        // Save the layout changes
                        item.Editing.BeginEdit();
                        layoutField.Value = layoutDefinition.ToXml();
                        item.Editing.EndEdit();
                        sbSummary.Append("Item updated: " + item.Name).Append(", Rendering updated: " + rendering.RenderingItem.DisplayName).Append("<br />");
                    }
                }
            }
        }


        protected void btnPublish_Click(object sender, EventArgs e)
        {
            int count = 0;
            StringBuilder sb = new StringBuilder();
            try
            {
                sb.Append("Summary:").Append("<br/>");
                bool isSubitem = false;
                string strDB = drpDB.SelectedItem.Value;
                
                Database db = null;

                try
                {
                    db = Database.GetDatabase(strDB);
                   
                }
                catch(Exception ex)
                {
                    sb.Append(ex.Message).Append("<br/>");
                }

                if (db != null)
                {
                    string[] strArray = txtIDs.Text.Split(new string[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
                    //if (drpIsSubItem.SelectedIndex == 1)
                    //{
                    //    isSubitem = true;
                    //}

                    foreach (string valueSet in strArray)
                    {
                        var itemId = string.Empty;
                        var renderingId = string.Empty;
                        var newDatasorceId = string.Empty;

                        var valueArray = valueSet.Split(',');

                        if (valueArray.Length == 3)
                        {
                            itemId = valueArray[0];
                            renderingId = valueArray[1];
                            newDatasorceId = valueArray[2];
                        }
                        else
                        {
                            continue;
                        }

                        if (!string.IsNullOrEmpty(itemId) && !string.IsNullOrEmpty(renderingId) && !string.IsNullOrEmpty(newDatasorceId))
                        {
                            if (Sitecore.Data.ID.IsID(itemId) && Sitecore.Data.ID.IsID(renderingId) && Sitecore.Data.ID.IsID(newDatasorceId))
                            {
                                Item i = db.GetItem(itemId);
                                if (i == null || i.ID.ToString() == "{F344DBE2-BC34-49FB-8564-FD74048702D9}")
                                {
                                    sb.Append("Item not found: " + itemId).Append("<br/>");
                                    continue;
                                }
                                //PublishItem(i, isSubitem, DB, lang.Value);
                                UpdateRenderingDatasource(i, renderingId, newDatasorceId, ref sb);
                            }
                            else
                            {
                                continue;
                            }
                        }

                        count++;
                    }
                    sb.Append("Total items updated : " + count);
                }

            }
            catch (Exception ex)
            {
                lblError.Text = ex.ToString();
            }

            lblError.Text = sb.ToString();
        }
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Bulk Datasource Update Tool - Visit Dubai</h2>
        <table class="" style="width: 70%">
            <tr>
                <%-- <td style="width: 22%">Update Datasource:<asp:DropDownList ID="drpIsSubItem" runat="server">
                    <asp:ListItem Text="Without SubItem" Value="0"></asp:ListItem>
                    <asp:ListItem Text="With SubItem" Value="1"></asp:ListItem>
                </asp:DropDownList></td>--%>
                <td>Database:<asp:DropDownList ID="drpDB" runat="server">
                    <asp:ListItem Text="Master" Value="master"></asp:ListItem>
                    <asp:ListItem Text="Stage" Value="stage"></asp:ListItem>
                    <asp:ListItem Text="Web" Value="web"></asp:ListItem>
                    <asp:ListItem Text="HKG" Value="hkg"></asp:ListItem>
                </asp:DropDownList></td>
            </tr>
            <tr>
                <td>Please provide the input in <strong>ItemId,Rendering Id,Datasource Id</strong> format, e.g.:
                    <br />
                    {110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9},{885B8314-7D8C-4CBB-8000-01421EA8F406},{110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}
                </td>
            </tr>
            <tr>
                <%--<td style="vertical-align: top">
                    <asp:CheckBoxList ID="chkLang" runat="server" Visible="false">
                        <asp:ListItem Value="en">English</asp:ListItem>
                        <asp:ListItem Value="ar">Arabic</asp:ListItem>
                        <asp:ListItem Value="az">Azeri</asp:ListItem>
                        <asp:ListItem Value="cs">Czech</asp:ListItem>
                        <asp:ListItem Value="de">German</asp:ListItem>
                        <asp:ListItem Value="es">Spanish</asp:ListItem>
                        <asp:ListItem Value="fr">French</asp:ListItem>
                        <asp:ListItem Value="id">Indonesian</asp:ListItem>
                        <asp:ListItem Value="it">Italian</asp:ListItem>
                        <asp:ListItem Value="ja">Japanese</asp:ListItem>
                        <asp:ListItem Value="ko">Korean</asp:ListItem>
                        <asp:ListItem Value="nl">Dutch</asp:ListItem>
                        <asp:ListItem Value="pl">Polish</asp:ListItem>
                        <asp:ListItem Value="pt">Portuguese</asp:ListItem>
                        <asp:ListItem Value="ru">Russian</asp:ListItem>
                        <asp:ListItem Value="sv">Swedish</asp:ListItem>
                        <asp:ListItem Value="uk">Ukrainian</asp:ListItem>
                        <asp:ListItem Value="hk">Cantonese</asp:ListItem>
                    </asp:CheckBoxList>
                </td>--%>
                <td style="vertical-align: top">
                    <asp:TextBox ID="txtIDs" TextMode="MultiLine" Rows="50" runat="server" Width="98%"></asp:TextBox></td>
            </tr>
            <tr>
                <td colspan="2">
                    <asp:Button ID="btnPublish" runat="server" Text="Update Datsource" OnClick="btnPublish_Click" /></td>
            </tr>
            <tr>
                <td colspan="2">
                    <asp:Label ID="lblError" runat="server"></asp:Label>
                </td>
            </tr>
        </table>

    </form>
</body>
</html>
