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
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.Compression" %>



<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Bulk Media Export Tool</title>
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
                Response.Redirect("login.aspx?returnUrl=bulkmediaexport.aspx");
            }
        }


        protected void btnPublish_Click(object sender, EventArgs e)
        {
            int count = 0;
            StringBuilder sb = new StringBuilder();

            sb.Append("Summary:").Append("<br/>");

            {
                string strDB = drpDB.SelectedItem.Value;
                Database db = null;

                string spath = Server.MapPath("~/temp");


                if (!string.IsNullOrEmpty(txtMediaParentPath.Text))
                {
                    // Make sure we can connect to the Sitecore db
                    db = Database.GetDatabase(strDB);

                    if (db != null)
                    {
                        // Get the parent media folder from database
                        var parentMediaFolderItem = db.GetItem(txtMediaParentPath.Text);
                        if (parentMediaFolderItem != null && parentMediaFolderItem.HasChildren)
                        {
                            try
                            {
                                var imagesRoot = db.GetItem(txtMediaParentPath.Text);
                                if (imagesRoot != null && imagesRoot.HasChildren)
                                {
                                    var children = imagesRoot.Children;
                                    //ZipStorer zip = null;
                                    // media folder
                                    var mediaDir = Directory.CreateDirectory(spath + "\\Bulk-Media-Export\\" + imagesRoot.Name);
                                    foreach (Item child in children)
                                    {
                                        FlushMediaItem(child, mediaDir.FullName);
                                    }

                                    try
                                    {
                                        ZipFile.CreateFromDirectory(mediaDir.FullName, mediaDir.FullName + ".zip");
                                        sb.Append(mediaDir.FullName).Append("<br />");
                                        using (var memoryStream = new MemoryStream())
                                        {
                                            //using (ZipArchive archive = ZipFile.Open(zipPath, ZipArchiveMode.Update))
                                            //{
                                            //    archive.c
                                            //}
                                            using (var fileStream = new FileStream(mediaDir.FullName + ".zip", FileMode.Open))
                                            {
                                                sb.Append(";;;;;;");
                                                memoryStream.Seek(0, SeekOrigin.Begin);
                                                fileStream.CopyTo(memoryStream);

                                                Directory.Delete(mediaDir.FullName, true);
                                                //var array = mediaDir.FullName.Split('\\');
                                                //var name = array[array.Length - 1];
                                               // sb.Append("FILE NAE:" + name).Append("<br />");
                                                //Response.AppendHeader("content-disposition", "attachment; filename=" + name + ".zip");
                                                //Response.ContentType = "application/zip";
                                                Response.Write(memoryStream);
                                            }
                                        }

                                    }
                                    catch (Exception ex)
                                    {
                                        sb.Append(ex.Message).Append("<br />");
                                    }
                                }
                            }
                            catch (Exception ex)
                            {
                                sb.Append(ex.StackTrace).Append("<br />");
                            }
                        }

                    }

                }
            }

            count++;
            sb.Append("Total items updated : " + count);

            lblError.Text = sb.ToString();
        }

        public void FlushMediaItem(Item child, string ParentPath)
        {
            if (child.TemplateID.ToString() == "{F1828A2C-7E5D-4BBD-98CA-320474871548}" || child.TemplateID.ToString() == "{DAF085E8-602E-43A6-8299-038FF171349F}")
            {

                var mediaItem = (MediaItem)child;
                var ext = mediaItem.Extension;

                var media = Sitecore.Resources.Media.MediaManager.GetMedia(child);
                var stream = media.GetStream();
                var filePath = Path.Combine(ParentPath, child.Name + "." + ext);

                using (var targetStream = File.OpenWrite(filePath))
                {
                    stream.CopyTo(targetStream);
                    targetStream.Flush();

                }
                //using (FileStream zipToOpen = new FileStream(ParentPath + ".zip", FileMode.Open))
                //{
                //    using (ZipArchive archive = new ZipArchive(zipToOpen, ZipArchiveMode.Update, true))
                //    {
                //        //Create a zip entry for each FileName in the FileName array 
                //        var zipArchiveEntry = archive.CreateEntry(mediaItem.Name + "." + media.Extension);

                //        using (Stream zipEntryStream = zipArchiveEntry.Open())
                //        {
                //            //Copy the attachment stream to the zip entry stream

                //            stream.CopyTo(zipEntryStream);
                //        }

                //        //  targetStream.Flush();

                //    }
                //}
            }
        }
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Bulk Media Update Tool - Visit Dubai</h2>
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
            </tr>
            <tr>

                <td style="vertical-align: top">
                    <asp:TextBox ID="txtMediaParentPath" TextMode="SingleLine" Rows="50" runat="server" Width="98%"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td colspan="2">
                    <asp:Button ID="btnPublish" runat="server" Text="Export Media" OnClick="btnPublish_Click" /></td>
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
