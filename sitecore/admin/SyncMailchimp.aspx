<%@ Page Language="C#" AutoEventWireup="true" Debug="true" %>

<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.IO" %>
<%@ Import Namespace="Sitecore.Data.Archiving" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="Sitecore.Links" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Net.Http.Headers" %>
<%@ Import Namespace="System.Net.Http" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Runtime.Serialization" %>
<%@ Import Namespace="System.Runtime.Serialization.Json" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Web.UI.HtmlControls" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="Sitecore.Zip" %>
<%@ Import Namespace="Sitecore.ContentSearch" %>
<%@ Import Namespace="Sitecore.ContentSearch.SearchTypes" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Diagnostics" %>


<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Sync VD Tables with MailChimp</title>
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

        .positionAbsolute {
            position: absolute;
        }
    </style>
    <script language="CS" runat="server"> 
        StringBuilder sb;
        DataTable tb;
        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAdministrator == false)
            {
                Response.Redirect("login.aspx?returnUrl=SyncMailchimp.aspx");
            }
        }

        protected void btnSyncTables_Click(object sender, EventArgs e)
        {
            // Create new stopwatch.
            Stopwatch stopwatch = new Stopwatch();

            // Begin timing.
            stopwatch.Start();

            ListDictionary Tables = new ListDictionary();
            Tables.Add("Users", "d9f23d1fb1");
            Tables.Add("HiddenGemLikes", "3abbc26f83");
            Tables.Add("VDDownloadsInfos", "1e8635ec8c");
            Tables.Add("NewsletterSubscription", "9b94ff5f16");

            List<string> MailChimpTableIDs = new List<string>();

            StringBuilder build = new StringBuilder();
            //Building an HTML string.
            StringBuilder html = new StringBuilder();

            foreach (var myTable in Tables.Keys)
            {
                html.AppendLine("<br /> <br />" + myTable.ToString() + "<br /> <br />");
                var strSelectQuery = @"SELECT * FROM " + myTable.ToString();
                var TableData = GetDataTable(strSelectQuery, "external");
                //List<users> MyUsers = new List<users>();
                StringBuilder jsonStringList = new StringBuilder();
                if (TableData.Rows.Count > 0)
                {
                    jsonStringList.Append("{\"operations\" : [");

                    var hashID = "";
                    int rowCount = TableData.Rows.Count;
                    int currentCount = 0;

                    int columnTotalCount = TableData.Columns.Count;
                    int columnCurrentCount = 0;

                    int currentRowCount = 0;
                    bool isLastRecordForRequest = false;

                    foreach (DataRow dataRow in TableData.Rows)
                    {
                        currentRowCount = currentRowCount + 1;
                        if (currentRowCount < 300)
                        {

                            if (currentRowCount == 299)
                            {
                                isLastRecordForRequest = true;
                            }
                            columnCurrentCount = 0;

                            if (myTable.ToString().ToLower().Equals("hiddengemlikes"))
                            {
                                hashID = CalculateMD5Hash(dataRow["EmailId"].ToString().Trim());
                                jsonStringList.Append("{\"method\" : \"PUT\",\"path\" : \"lists/" + Tables[myTable.ToString()] + "/members/" + hashID + "\", \"body\": \"{\\\"email_address\\\":\\\"" + dataRow["EmailId"].ToString().Trim() + "\\\", \\\"status\\\":\\\"subscribed\\\",\\\"merge_fields\\\": {");
                            }
                            else
                            {
                                hashID = CalculateMD5Hash(dataRow["Email"].ToString().Trim());
                                jsonStringList.Append("{\"method\" : \"PUT\",\"path\" : \"lists/" + Tables[myTable.ToString()] + "/members/" + hashID + "\", \"body\": \"{\\\"email_address\\\":\\\"" + dataRow["Email"].ToString().Trim() + "\\\", \\\"status\\\":\\\"subscribed\\\",\\\"merge_fields\\\": {");
                            }

                            currentCount = currentCount + 1;
                            //html.Append("<tr>");

                            List<string> mergeFieldString = new List<string>();
                            foreach (DataColumn column in TableData.Columns)
                            {
                                columnCurrentCount = columnCurrentCount + 1;

                                //html.Append("<td>");
                                //html.Append(dataRow[column.ColumnName]);

                                //Merge Column String
                                //Output String: \\\"FNAME\\\": \\\"" + dataRow["First Name"].ToString() + "\\\", \\\"LNAME\\\": \\\"" + dataRow["Last Name"].ToString() + "\\\"

                                if (column.ColumnName.ToLower().Contains("password"))
                                {
                                    //Do Nothing
                                }
                                else
                                {
                                    if (column.ColumnName.Length > 2)
                                    {
                                        //Output String = \\\"FNAME\\\": \\\"" + dataRow["First Name"].ToString() + "\\\"
                                        var mailChimpColumnName = string.Empty;
                                        if (column.ColumnName.Length > 10)
                                        {
                                            mailChimpColumnName = column.ColumnName.Replace(" ", "").ToUpper();
                                            if (myTable.ToString().ToLower().Equals("hiddengemlikes"))
                                            {
                                                if (mailChimpColumnName == "HIDDENGEMSITEMID")
                                                {
                                                    mailChimpColumnName = "ITEMID";
                                                }
                                                if (mailChimpColumnName == "HIDDENGEMSTITLE")
                                                {
                                                    mailChimpColumnName = "GEMSTITLE";
                                                }
                                            }
                                            else
                                            {
                                                mailChimpColumnName = mailChimpColumnName.Take(10).ToString();
                                            }
                                        }
                                        else
                                        {
                                            mailChimpColumnName = column.ColumnName.Replace(" ", "").ToUpper();
                                        }
                                        if (columnCurrentCount == columnTotalCount || isLastRecordForRequest)
                                        {
                                            //Do not add Comma at the end

                                            mergeFieldString.Add("\\\"" + mailChimpColumnName.ToUpper() + "\\\": \\\"" + dataRow[column.ColumnName].ToString().Replace("\\", "-").TrimEnd() + "\\\"");
                                        }
                                        else
                                        {
                                            if (mailChimpColumnName.ToString().ToLower().Contains("description"))
                                            {

                                            }
                                            else
                                            {
                                                mergeFieldString.Add("\\\"" + mailChimpColumnName.ToUpper() + "\\\": \\\"" + dataRow[column.ColumnName].ToString().Replace("\\", "").TrimEnd() + "\\\",");
                                            }
                                            //Needed to add replace \\ because in First Name there is \ at one of the record.
                                        }
                                    }
                                }
                            }
                            jsonStringList.Append(String.Join("", mergeFieldString.ToArray()));

                            if (currentCount == rowCount || isLastRecordForRequest)
                            {
                                //Do not add Comma (,) at the end.
                                jsonStringList.Append("}}\"}");
                            }
                            else
                            {
                                jsonStringList.Append("}}\"},");
                            }

                            if (isLastRecordForRequest)
                            {
                                isLastRecordForRequest = false;
                                currentRowCount = 0;
                                jsonStringList.Append("]}");
                                //html.AppendLine("<br /> <br /> JSON String: " + jsonStringList.ToString().Trim());
                                CreateWebRequest(ref jsonStringList, ref html);
                                jsonStringList.Clear();
                                jsonStringList.Append("{\"operations\" : [");
                                html.AppendLine("<br /> <br /> <br /> Procceeding with Next Request<br /> <br /> <br />");
                            }
                        }
                    }

                    jsonStringList.Append("]}");
                    CreateWebRequest(ref jsonStringList, ref html);
                    html.AppendLine("<br /> <br /> JSON String: " + jsonStringList.ToString().Trim());

                }
            }

            // Stop timing.
            stopwatch.Stop();

            // Write result.
            html.AppendLine("<br/> <br/> <br/> Time elapsed: " + stopwatch.Elapsed);

            lblSummary.Text = html.ToString();

        }

        public void CreateWebRequest(ref StringBuilder jsonStringList, ref StringBuilder html)
        {
            //Sitecore.Diagnostics.Log.Info(jsonStringList.ToString().Trim(), this);
            var webRequest = (HttpWebRequest)WebRequest.Create("https://us16.api.mailchimp.com/3.0/batches");
            webRequest.Method = "POST";
            webRequest.ContentType = "application/json";
            //webRequest.Headers.Add("Authorization", "your apikey");
            //webRequest.Headers.Add("user", "'anystring: your apikey'");
            //webRequest.Host = "yourmailchimp.api.mailchimp.com";
            webRequest.Timeout = 500000;

            //https://docs.microsoft.com/en-us/dotnet/framework/network-programming/how-to-send-data-using-the-webrequest-class
            Stream dataStream = webRequest.GetRequestStream();
            byte[] byteArray = Encoding.UTF8.GetBytes(jsonStringList.ToString().Trim());
            dataStream.Write(byteArray, 0, byteArray.Length);
            dataStream.Close();

            try
            {
                using (var webResponse = (HttpWebResponse)webRequest.GetResponse())
                {
                    using (var stream = webResponse.GetResponseStream())
                    {
                        //if (stream != null)
                        //{
                        //    using (var memoryStream = new MemoryStream())
                        //    {
                        //        using (var reader = new StreamReader(stream, Encoding.UTF8))
                        //        {
                        //            var jSon = Serialize<string>(reader.ReadToEnd());
                        //            html.AppendLine(jSon);
                        //        }
                        //    }
                        //}
                    }
                }
            }
            catch (WebException ex)
            {
                html.Append("<br>Error Status: " + ex.Status + "<br>");
                html.Append("<br>Error Message: " + ex.Message + "<br>");
                using (var stream = ex.Response.GetResponseStream())
                using (var reader = new StreamReader(stream))
                {
                    html.Append("<br>Response String: " + reader.ReadToEnd() + "<br>");
                }

                html.Append("<br />Json String Error: " + jsonStringList.ToString().Trim() + "<br />");

            }
        }

        // Hash an input string and return the hash as
        // a 32 character hexadecimal string.
        static string CalculateMD5Hash(string input)
        {
            // Create a new instance of the MD5CryptoServiceProvider object.
            MD5CryptoServiceProvider md5Hasher = new MD5CryptoServiceProvider();

            // Convert the input string to a byte array and compute the hash.
            byte[] data = md5Hasher.ComputeHash(Encoding.Default.GetBytes(input));

            // Create a new Stringbuilder to collect the bytes
            // and create a string.
            StringBuilder sBuilder = new StringBuilder();

            // Loop through each byte of the hashed data 
            // and format each one as a hexadecimal string.
            for (int i = 0; i < data.Length; i++)
            {
                sBuilder.Append(data[i].ToString("x2"));
            }

            // Return the hexadecimal string.
            return sBuilder.ToString();
        }

        public static string Serialize<T>(T obj)
        {
            DataContractJsonSerializer serializer = new DataContractJsonSerializer(obj.GetType());
            using (MemoryStream ms = new MemoryStream())
            {
                serializer.WriteObject(ms, obj);
                return Encoding.Default.GetString(ms.ToArray());
            }
        }

        public DataTable GetDataTable(string query, string strConnectionString)
        {
            DataTable genericTable = new DataTable();
            try
            {
                String ConnString = ConfigurationManager.ConnectionStrings[strConnectionString].ConnectionString + ";Connection Timeout=2500;";
                SqlDataAdapter adapter = new SqlDataAdapter();

                using (SqlConnection conn = new SqlConnection(ConnString))
                {
                    adapter.SelectCommand = new SqlCommand(query, conn);
                    adapter.SelectCommand.CommandTimeout = 300;
                    adapter.Fill(genericTable);
                }

            }
            catch (Exception ex)
            {
                //Sitecore.Diagnostics.Log.Error("There is an error in GetDataTable", this);
            }
            return genericTable;
        }

        public class users
        {
            public string Username { get; set; }
            public string Password { get; set; }
            public string FirstName { get; set; }
            public string LastName { get; set; }
            public string EmailAddress { get; set; }

        }

    </script>

</head>
<body>
    <form id="form1" runat="server">
        <h2>Sync Site Users with Mailchimp!</h2>
        <h4>Use this tool to sync all the Website Users with Mailchimp</h4>
        <table>
            <tr>
                <td>
                    <asp:Button ID="btnSyncUsers" runat="server" Text="Sync Tables" OnClick="btnSyncTables_Click" /></td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="lblSummary" CssClass="positionAbsolute" runat="server"></asp:Label></td>
            </tr>
        </table>
    </form>
</body>
</html>
