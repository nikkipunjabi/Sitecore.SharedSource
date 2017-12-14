<%@ Page Language="C#" AutoEventWireup="true" Debug="true" %>

<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="Sitecore.Layouts" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>
<%@ Import Namespace="Sitecore.Collections" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Sitecore.Data.Managers" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="Sitecore.SharedSource" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Bulk - Add Sub-Layout and Update Data-Source</title>
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
        StringBuilder sb;
        DataTable tb;
        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAuthenticated == false)
            {
                Response.Redirect("login.aspx?returnUrl=BulkAddSublayout.aspx");
            }
        }

        protected void btnGetReport_Click(object sender, EventArgs e)
        {
            try
            {
                StringBuilder sb = new StringBuilder();
                sb.Append("Summary:").Append("<br/>");

                string path = txtPath.Text;
                Database db = Database.GetDatabase("master");
                Item parent = db.GetItem(path);
                bool renderingAlreadyExist = false;

                if (parent != null)
                {
                    // Default device from Sitecore
                    var deviceItem = db.GetItem("{FE5D7FDF-89C0-4D99-9AA3-B5FBD009C9F3}");
                    DeviceItem device = new DeviceItem(deviceItem);

                    foreach (Item childItem in parent.Axes.GetDescendants())
                    {
                        if (!string.IsNullOrWhiteSpace(txtTemplateID.Text))
                        {
                            Guid templateIDGuid = new Guid();
                            if (Guid.TryParse(txtTemplateID.Text, out templateIDGuid))
                            {
                                Sitecore.Data.ID id = new Sitecore.Data.ID(templateIDGuid);
                                if (childItem.TemplateID != id)
                                {
                                    string log = string.Format("Template do not match. Item Path: {0} <br />", childItem.Paths.FullPath);
                                    sb.AppendLine(log);
                                    Sitecore.Diagnostics.Log.Info(log, this);

                                    continue;
                                }
                            }
                        }
                        if (childItem.Fields != null && childItem.Fields["__Renderings"] != null && childItem.Fields["__Renderings"].ToString() != string.Empty)
                        {
                            var renderings = childItem.Visualization.GetRenderings(device, true).Where(r => r.RenderingID == Sitecore.Data.ID.Parse(txtRenderingID.Text)).ToArray();
                            if (renderings.Count() > 0)
                            {
                                Sitecore.Diagnostics.Log.Info("Item not updated: " + childItem.Paths.Path + ", Message: Rendering already Exist. ID " + txtRenderingID.Text, this);
                                renderingAlreadyExist = true;
                            }


                            // Get the layout definitions and the device
                            Sitecore.Data.Fields.LayoutField layoutField = new Sitecore.Data.Fields.LayoutField(childItem.Fields[Sitecore.FieldIDs.LayoutField]);

                            if (!string.IsNullOrEmpty(layoutField.Value))
                            {
                                Sitecore.Layouts.LayoutDefinition layoutDefinition = Sitecore.Layouts.LayoutDefinition.Parse(layoutField.Value);

                                Sitecore.Layouts.DeviceDefinition deviceDefinition = layoutDefinition.GetDevice(device.ID.ToString());

                                if (deviceDefinition.Renderings != null && deviceDefinition.Renderings.Count > 0)
                                {

                                    var renderingID = txtRenderingID.Text;
                                    if (renderingAlreadyExist)
                                    {
                                        var renderingItem = deviceDefinition.GetRendering(renderingID);
                                        if (renderingItem != null)
                                        {
                                            // Update the renderings datasource value accordingly 
                                            renderingItem.Datasource = txtNewDataSourceID.Text;
                                            renderingItem.Placeholder = txtPlaceholderKey.Text;
                                            // Save the layout changes
                                            childItem.Editing.BeginEdit();
                                            layoutField.Value = layoutDefinition.ToXml();
                                            childItem.Editing.EndEdit();

                                            sb.Append("Item updated: " + childItem.Paths.Path).Append(", Rendering updated.").Append("<br />");
                                        }
                                    }
                                    else
                                    {
                                        RenderingDefinition def = new RenderingDefinition();
                                        def.ItemID = renderingID;
                                        def.Datasource = txtNewDataSourceID.Text;
                                        def.Placeholder = txtPlaceholderKey.Text;
                                        deviceDefinition.AddRendering(def);
                                        sb.Append("Item updated: " + childItem.Paths.Path).Append(", Rendering Added.").Append("<br />");
                                    }

                                    // Save the layout changes
                                    childItem.Editing.BeginEdit();
                                    layoutField.Value = layoutDefinition.ToXml();
                                    childItem.Editing.EndEdit();
                                }
                            }
                        }
                    }
                    lblCount.Text = sb.ToString();
                }
            }
            catch (Exception ex)
            {
                lblCount.Text = ex.ToString();
            }
        }

    </script>

</head>
<body>
    <form id="form1" runat="server">
        <h2>Add Sub-layout and Update Datasource in Bulk - Visit Dubai</h2>
        <h4>Use this tool to remove all the presentation rules from the sub-layout and also update the data-source</h4>
        <table>
            <tr>
                <td>Provide Parent Item Path:<asp:TextBox ID="txtPath" Width="500px" runat="server"></asp:TextBox></td>
                <td>Rendering ID:<asp:TextBox ID="txtRenderingID" Width="200px" runat="server"></asp:TextBox></td>
                <td>New DataSource ID:<asp:TextBox ID="txtNewDataSourceID" Width="200px" runat="server"></asp:TextBox></td>
                <td>Placeholder Key:<asp:TextBox ID="txtPlaceholderKey" Width="200px" runat="server"></asp:TextBox></td>
                <td>Template ID:<asp:TextBox ID="txtTemplateID" Width="200px" runat="server"></asp:TextBox></td>
                <td>
                    <asp:Button ID="btnGetReport" runat="server" Text="Execute" OnClick="btnGetReport_Click" /></td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="lblCount" runat="server"></asp:Label></td>
            </tr>
            <tr>
                <td>&nbsp;</td>
            </tr>
            <tr>
                <td colspan="3">
                    <asp:GridView ID="grdLanguageReport" CssClass="table-style-three" runat="server"></asp:GridView>
                </td>
            </tr>
        </table>
    </form>
</body>
</html>