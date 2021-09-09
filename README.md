## Setting up GitLab SSH key

Reference: [how to generate a SSH key](https://gitlab.endpoints.cn-gaming-cicd.cloud.goog/help/ssh/README#generating-a-new-ssh-key-pair)

Open a terminal. You may want to use an email address for the comment "&lt;comment>".


```
ssh-keygen -t rsa -b 2048 -C "<comment>"
```


This command generate a SSH key in **~/.ssh**, which include** id_rsa** and **id_rsa.pub**


```
cat ~/.ssh/id_rsa.pub ​​| clip
```


Copy the content in **id_rsa.pub**, paste it on gitlab.



<p id="gdcalert1" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image1.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert2">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image1.png "image_tooltip")



Click **Add key.**

Test the SSH connection,  replacing gitlab.example.com with your GitLab instance URL.


```
ssh -T git@gitlab.example.com
```


If this is the first time you connect, you should verify the authenticity of the GitLab host. If you see a message like:


```
The authenticity of host 'gitlab.example.com (35.231.145.151)' can't be established.
ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'gitlab.example.com' (ECDSA) to the list of known hosts.
```


Type yes and press Enter.



<p id="gdcalert2" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image2.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert3">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image2.png "image_tooltip")


You should receive a **Welcome to GitLab, @username! **Message.


## Save SSH key to secret manager

On the **Secret Manager** page, click **Create Secret**.

On the **Create secret** page, under **Name**, enter a name for your secret.

In the **Secret value** field, enter a name for your secret or upload a file. \
To upload your SSH key file, click **Upload** to include your **~/.ssh/id_rsa** file.

Or paste the content in **~/.ssh/id_rsa** file to the **Secret value** field.

Leave the **Regions** section unchanged.

Click the **Create secret** button to create your secret.


## Setting up GKE cluster and Agones using one command


Write [terraform scripts](https://gitlab.endpoints.cn-gaming-cicd.cloud.goog/gaming-ci-cd-automation/core/-/blob/main/main.tf) to create a VPC and GKE cluster, use Helm to install Agones.
Write a [cloud build config file](https://gitlab.endpoints.cn-gaming-cicd.cloud.goog/gaming-ci-cd-automation/core/-/blob/main/cloud-build/cloud_build_terraform.yaml) to apply terraform scripts. It includes the following steps:
    1. SSH authentication and clone the Gitlab repository
    2. Replace the project id field
    3. Replace the cluster name field
    4. Terraform init, plan and apply
Go to the cloud build, create a webhook trigger:
    Click **Create trigger**.
    Enter the following trigger settings:
        **Name**: A name for your trigger.
        **Event**: Select **Webhook event** to set up your trigger to start builds in response to incoming webhook events.
        **Webhook URL**: Use the webhook URL to authenticate incoming webhook events.
        use an existing secret:
            Select **Use existing**.
            In the **Secret** field, select the name of the secret you want to use from the drop-down menu or follow the instructions to add a secret by resource ID.
            In the **Secret version** field, select your secret version from the drop-down menu.
    **Configuration**: Copy and paste the inline build config file.
    **Substitutions**: define 2 substitution variables using this field.

    
<p id="gdcalert3" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image3.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert4">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image3.png "image_tooltip")


Use the “curl” command to trigger cloud build, specify the cluster name and the region  using the JSON format, the parameters will be replaced dynamically in the cloud build config file.

```
curl -X POST -H "application/json" "https://cloudbuild.googleapis.com/v1/projects/cn-gaming-cicd/triggers/core-trigger:webhook?key=AIzaSyBe45IJgmgE3Ssoekh77cl3Z1riBmG7N_I&secret=9LvtgKaNTnKA1ATGBA_167JJPIWynkbB" -d '{"cluster_name":"cluster-xyz", "region":"us-central1"}'
```



## Apply the Configuration of the Fleet by push events



Write a [fleet config file](https://gitlab.endpoints.cn-gaming-cicd.cloud.goog/gaming-ci-cd-automation/core/-/blob/main/modules/agones/fleet_configs_simple.yaml).In this demo, we use the simple game server to test the Quilkin proxy. 
    1. Create a fleet with 2 replica simple game servers. we’ll take the example container  that Agones provides for the simple game server.
    2. Create a ConfigMap to store the yaml for a static configuration for Quilkin that will accept connections on port 26002 and route then to the simple game server on port 7654.
        
        The CaptureBytes filter will find the first 3 bytes within a packet, and capture it into Filter Dynamic Metadata, so that it can be utilised by filters further down the chain, which is the TokenRouter filter. This TokenRouter Filter compares the token found in the Filter Dynamic Metadata from the  CaptureBytes Filter, and compares it to Endpoint's tokens, and sends packets to those Endpoints only if there is a match. 
        
        In this example, the base64 encoded token is “YWJj”, if the token is found in the first 3 bytes within the packet, it will be removed and sended the rest of the message to the “127.0.0.1:7654”, which is listened by the simple game server. 
    
    
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: quilkin-config-simple
data:
  quilkin.yaml: |
    version: v1alpha1
    proxy:
      id: proxy-demo-simple
      port: 26002
    static:
      filters:
        - name: quilkin.extensions.filters.debug.v1alpha1.Debug # Debug filter: every packet will be logged
          config:
            id: debug-1
    
        - name: quilkin.extensions.filters.capture_bytes.v1alpha1.CaptureBytes # Capture and remove the authentication token
          config:
              strategy: PREFIX
              size: 3
              remove: true
              metadataKey: quilkin.dev
        - name: quilkin.extensions.filters.token_router.v1alpha1.TokenRouter
          config:
              metadataKey: quilkin.dev
      endpoints: 
          address: 127.0.0.1:7654
          metadata:
              quilkin.dev:
                tokens:
                    - YWJj # abc
                    - MXg3aWp5Ng== # Authentication is provided by these ids, and matched against 
                    - OGdqM3YyaQ== # the value stored in Filter dynamic metadata
```    
    3. Run Quilkin alongside each dedicated game server as a sidecar.
Write the [cloud build config file](https://gitlab.endpoints.cn-gaming-cicd.cloud.goog/gaming-ci-cd-automation/core/-/blob/main/cloud-build/cloud_build_fleet_configs.yaml) to apply the fleet configurations. It includes the following steps:
    1. SSH authentication and clone the Gitlab repository
    2. Connect the GKE cluster
    3. Apply the fleet_config.yaml file
Create the substitution variables.

    

<p id="gdcalert4" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image4.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert5">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image4.png "image_tooltip")


Use “curl” command to trigger cloud build, it will apply the fleet configurations with specified yaml file name. In this demo, we use the simple game server to test the Quilkin proxy, so “config_file” is “fleet_configs_simple.yaml”.

```
curl -X POST -H "application/json" "https://cloudbuild.googleapis.com/v1/projects/cn-gaming-cicd/triggers/fleet-config-trigger:webhook?key=AIzaSyBe45IJgmgE3Ssoekh77cl3Z1riBmG7N_I&secret=xh8twKFPVoA4SG2J9MxXY20sxD50EMVd" -d '{"cluster_name":"cluster-xyz", "region":"us-central1", "config_file":"fleet_configs_simple.yaml"}'
```


Test the fleet creation.
    1. In Cloud Build history, it was successfully built.
    2. In the cloud shell, verify that gameservers were created, and the state is ready.

```
Kubectl get gs
```



The output should look like this:



<p id="gdcalert6" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image6.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert7">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image6.png "image_tooltip")



## Test the Quilkin Proxy

Run [SimpleGameServerQuilkinTest.py](https://gitlab.endpoints.cn-gaming-cicd.cloud.goog/gaming-ci-cd-automation/core/-/blob/main/QuilkinTest/SimpleGameServerQuilkinTest.py) to send a UDP package of message “abcEXIT”, “abc” is the first 3 bytes of the message, and it matches the token, so it will be removed by the filter, and pass “EXIT” to the game server.

The simple game server will echo the message back, and the message should be “EXIT”.



<p id="gdcalert7" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image7.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert8">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image7.png "image_tooltip")


After the game server “simple-game-server-7qsr8-tlmvh” receives an “EXIT” message, it will shut down the game server, and create a new one. You should see that a new game server “simple-game-server-7qsr8-gszqf” is created, the port is changed from “7040” to “7537”.



<p id="gdcalert8" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image8.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert9">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image8.png "image_tooltip")

