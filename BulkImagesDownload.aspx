<%@ Page Language="C#" AutoEventWireup="true" Debug="true" %>

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
    <title>Bulk Delete</title>

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
            if (Sitecore.Context.User.IsAdministrator == false)
            {
                Response.Redirect("login.aspx?returnUrl=bulkdelete.aspx");
            }
        }

        protected void btnDelete_Click(object sender, EventArgs e)
        {

            string tempFolderPath = Sitecore.Configuration.Settings.TempFolderPath;
            tempFolderPath = HttpContext.Current.Server.MapPath(tempFolderPath);
            string zipName = "media" + DateTime.Now.Ticks + ".zip";
            ZipWriter zipWriter = new ZipWriter(Path.Combine(tempFolderPath, zipName));

            var database = Database.GetDatabase("master");
            var images = database.SelectItems("/sitecore/media library/your folder/*");

            foreach (var image in images)
            {
                if (MediaManager.HasMediaContent(image))
                {
                    var mediaItem = (MediaItem)image;
                    var media = MediaManager.GetMedia(mediaItem);
                    var stream = media.GetStream();

                    zipWriter.AddEntry(mediaItem.Name + "." + mediaItem.Extension, stream.Stream);
                }
            }

            zipWriter.Dispose();

            HttpContext.Current.Response.Clear();
            HttpContext.Current.Response.ContentType = "application/zip";
            HttpContext.Current.Response.AppendHeader("Content-Disposition", string.Format("inline;filename=\"{0}\"", zipName));
            HttpContext.Current.Response.StatusCode = (int)HttpStatusCode.OK;
            HttpContext.Current.Response.BufferOutput = true;

            using (StreamReader sr = new StreamReader(Path.Combine(tempFolderPath, zipName)))
            {
                sr.BaseStream.CopyTo(HttpContext.Current.Response.OutputStream);
                HttpContext.Current.Response.Flush();
                HttpContext.Current.Response.End();
            }

            //int count = 0;
            //StringBuilder sb = new StringBuilder();
            //bool isSubitem = false;
            //try
            //{
            //    sb.Append("Delete Summary:").Append("<br/>");
            //    string[] s = txtIDs.Text.Split(new string[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);

            //    string DB = drpDB.SelectedItem.Value;
            //    Database db = Database.GetDatabase(DB);
            //    if (drpIsSubItem.SelectedIndex == 1)
            //    {
            //        isSubitem = true;
            //    }
            //    foreach (string ii in s)
            //    {
            //        Item i = db.GetItem(ii);
            //        if (isSubitem == false)
            //        {
            //            if (i == null || i.HasChildren || i.ID.ToString() == "{F344DBE2-BC34-49FB-8564-FD74048702D9}") { sb.Append("Cannot delete this item: " + ii).Append("<br/>"); continue; }
            //        }
            //        else
            //        {
            //            if (i == null || i.ID.ToString() == "{F344DBE2-BC34-49FB-8564-FD74048702D9}") { sb.Append("Cannot delete this item: " + ii).Append("<br/>"); continue; }
            //        }

            //        i.Recycle();
            //        sb.Append("Item deleted:").Append(i.ID).Append("<br/>");
            //        count++;
            //    }

            //    sb.Append("Total delete item from above given list: " + count);
            //}
            //catch (Exception ex)
            //{
            //    lblError.Text = ex.ToString();
            //}
            //lblError.Text = sb.ToString();
        }

    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Bulk Delete Tool</h2>
        <table class="table-style-three">
            <tr>
                <td style="width: 20%">Delete:<asp:DropDownList ID="drpIsSubItem" runat="server">
                    <asp:ListItem Text="Without SubItem" Value="0"></asp:ListItem>
                    <asp:ListItem Text="With SubItem" Value="1"></asp:ListItem>
                </asp:DropDownList></td>

                <td>Database:<asp:DropDownList ID="drpDB" runat="server">
                    <asp:ListItem Text="Master" Value="master"></asp:ListItem>
                    <asp:ListItem Text="Stage" Value="stage"></asp:ListItem>
                    <asp:ListItem Text="Web" Value="web"></asp:ListItem>
                </asp:DropDownList></td>
            </tr>
            <tr>
                <td colspan="2" style="vertical-align: top">
                    <asp:TextBox ID="txtIDs" TextMode="MultiLine" Rows="50" runat="server" Height="400px" Width="98%"></asp:TextBox></td>
            </tr>
            <tr>
                <td colspan="2">
                    <asp:Button ID="btnDelete" runat="server" Text="Delete" OnClick="btnDelete_Click" /></td>
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
