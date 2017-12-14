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
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Bulk Update Tool</title>

    <style>
        body {
            font-family: verdana, arial, sans-serif;
        }

        table.table-style-three {
            font-family: verdana, arial, sans-serif;
            font-size: 12px;
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
        string csv_file_path;
        Database db;
        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            string DB = drpDB.SelectedItem.Value;
            db = Database.GetDatabase(DB);
            if (Sitecore.Context.User.IsAuthenticated == false)
            {
                Response.Redirect("login.aspx?returnUrl=bulkupdate.aspx");
            }
        }

        protected void btnUploadAndUpdate_Click(object sender, EventArgs e)
        {
            if (uploadedFile.HasFile)
            {
                string spath = Server.MapPath("~/temp");
                csv_file_path = spath + "\\" + uploadedFile.FileName;
                uploadedFile.SaveAs(csv_file_path);

                string parentNode = txtParentPath.Text;
                Language lang = Sitecore.Globalization.Language.Parse(txtLang.Text);
                var parentItem = db.GetItem(parentNode, lang);

                DataTable dt = FetchData(csv_file_path);
                int childNumber = 0;

                foreach (DataRow row in dt.Rows)
                {
                    if (dt.Columns[0].ColumnName.Equals("ID"))
                    {
                        for (int i = 1; i < dt.Columns.Count; i++) //Need to start from 2nd column as first is ID
                        {
                            Item item = db.GetItem(row[0].ToString(), lang);
                            string replaceComma = row[i].ToString().Replace("#123#", ",");
                            UpdateItemFields(item, dt.Columns[i].ColumnName, replaceComma, txtTemplateName.Text);
                        }
                    }
                    else
                    {
                        for (int i = 0; i < dt.Columns.Count; i++)
                        {
                            string replaceComma = row[i].ToString().Replace("#123#", ",");
                            UpdateAllFields(parentItem, dt.Columns[i].ColumnName, replaceComma, childNumber, txtTemplateName.Text);
                        }
                        childNumber++;
                    }
                }
            }
        }


        private void UpdateAllFields(Item parentItem, string fieldName, string newValue, int childNumber, string templateName)
        {
            if (parentItem != null)
            {
                using (new SecurityDisabler())
                {
                    Item childItem = parentItem.Children[childNumber];
                    if (childItem.Fields[fieldName] != null && childItem.TemplateName == templateName)
                    {
                        using (new Sitecore.SecurityModel.SecurityDisabler())
                        {
                            childItem.Editing.BeginEdit();
                            try
                            {
                                childItem[fieldName] = newValue;
                                Sitecore.Data.Fields.Field f = (Sitecore.Data.Fields.Field)childItem.Fields[fieldName];
                                if (f != null && f.Type == "Image")
                                {
                                    Sitecore.Data.Fields.ImageField imageField = (Sitecore.Data.Fields.ImageField)f;
                                    Item imageItem = db.GetItem(newValue);
                                    if (imageItem != null)
                                    {
                                        imageField.MediaID = imageItem.ID;
                                    }
                                }
                            }
                            finally
                            {
                                childItem.Editing.AcceptChanges();
                                childItem.Editing.EndEdit();
                            }
                        }
                    }
                }
            }
        }

        private void UpdateItemFields(Item item, string fieldName, string newValue, string templateName)
        {
            if (item != null)
            {
                using (new SecurityDisabler())
                {
                    if (item.Fields[fieldName] != null)
                    {
                        using (new Sitecore.SecurityModel.SecurityDisabler())
                        {
                            item.Editing.BeginEdit();
                            try
                            {
                                item[fieldName] = newValue;
                                Sitecore.Data.Fields.Field f = (Sitecore.Data.Fields.Field)item.Fields[fieldName];
                                if (f != null && f.Type == "Image")
                                {
                                    Sitecore.Data.Fields.ImageField imageField = (Sitecore.Data.Fields.ImageField)f;
                                    Item imageItem = db.GetItem(newValue);
                                    imageField.MediaID = imageItem.ID;
                                }
                            }
                            finally
                            {
                                item.Editing.AcceptChanges();
                                item.Editing.EndEdit();
                            }
                        }
                    }
                }
            }
        }

        private DataTable FetchData(string filepath)
        {
            DataTable dt = new DataTable();

            if (File.Exists(filepath))
            {
                string[] data = File.ReadAllLines(filepath);

                string[] col = data[0].Split(',');

                foreach (string s in col)
                {
                    dt.Columns.Add(s, typeof(string));
                }


                for (int i = 1; i < data.Length; i++)
                {
                    string[] row = data[i].Split(new[] { ',' });
                    dt.Rows.Add(row);
                }
            }

            return dt;
        }


    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Bulk Update Tool</h2>
        <table class="table-style-three">
            <tr>
                <td>Parent Item Path:
                    <asp:TextBox ID="txtParentPath" runat="server" Width="500px"></asp:TextBox></td>
                <td>Template Name:
                    <asp:TextBox ID="txtTemplateName" runat="server"></asp:TextBox></td>
                <td>Language:<asp:TextBox ID="txtLang" Text="en" runat="server"></asp:TextBox></td>
                <td>Database:<asp:DropDownList ID="drpDB" runat="server">
                    <asp:ListItem Text="Master" Value="master"></asp:ListItem>
                    <asp:ListItem Text="Stage" Value="stage"></asp:ListItem>
                    <asp:ListItem Text="WEB" Value="web"></asp:ListItem>
                </asp:DropDownList></td>
            </tr>
            <tr>
                <td colspan="4">
                    <asp:FileUpload ID="uploadedFile" runat="server" /></td>
            </tr>
            <tr>
                <td colspan="4">
                    <asp:Button ID="btnUpload" OnClick="btnUploadAndUpdate_Click" Text="Upload and Update" runat="server" />
                    <mark>Please replace "," with #123# in CSV file before upload.<br />
                    </mark><br />
                    Checks<br />
                    <ol>
                        <li>Is CSV contains ID?</li>
                        <li>If yes, then column first name must be <b>ID</b></li>
                        <li>Is CSV contains Arabic text?</li>
                        <li>If yes, then save CSV by copy/paste in notepad and then save as CSV</li>
                    </ol>
                    <br />
                </td>

            </tr>
        </table>
    </form>
</body>
</html>
