# Lab 3: Monitoring

In this assignment, you will set up [Prometheus](https://prometheus.io) and [Grafana](https://grafana.com) in order to to monitor the entire virtual environment set up in the previous labs with.

## Learning goals

- Installing Prometheus and Node Exporter
- Configure basic system monitoring (CPU, memory, etc.)
- Monitor services
- Setting up a monitoring dashboard with Grafana

## Assessment criteria (L3)

To meet the standard, show that the following criteria are met:

- [ ] Show that the Prometheus server works:
    - Show targets in the webinterface. You should see all VMs as their host name, rather than their IP address.
    - Run a query for a metric
- [ ] Show the Grafana dashboard you created
- [ ] Demonstrate that you understand how your setup works beyond copying the assignment instructions to an LLM and pasting the results to the terminal or your lab report
- [ ] Show your lab report and cheat sheet! It should contain screenshots of consecutive steps and console output of commands you used.

In order to exceed expectations, implement one or more of the suggested extensions given below, or come up with your own.

- ⭐ Automate the setup of the Grafana dashboard, so that it is automatically created when you run the playbook.
- ⭐ Make the gathering of metrics more secure with e.g. stricter firewall rules (only the monitoring server can access the Node Exporter port), TLS/SSL, authentication, ...
- ⭐ Set up instrumentation for the services in your setup, e.g.
    - MariaDB service on `dmz020`.
    - The nginx service on `dmz010`.
    - DNS services
    - Docker on `infra010` and `dmz010`
    - The router (tip: monitoring network equipment is usually done over SNMP, the Simple Network Management Protocol)
- ⭐ Implement log aggregation with Grafana Loki and integrate this in your Grafana dashboard.
- ⭐ Set up alerting with Prometheus Alertmanager.

## 3.1. Install prerequisites

The necessary roles are available on Ansible Galaxy in the [Prometheus collection](https://galaxy.ansible.com/ui/repo/published/prometheus/prometheus/). Add this collection to your `requirements.yml` file and ensure it gets installed.

## 3.2. Install Node Exporter

The Prometheus server polls all monitored systems for any metrics that you expose. Basic system metrics can be provided by Prometheus' Node Exporter. We will install this first on all VMs so that the Prometheus server can collect these metrics when we set it up.

Install the `node_exporter` role from the Prometheus collection on all VMs in your setup. If the installation is successful, Node Exporter opens a server socket on port 9100. Use curl to check that you can access this port on all VMs, and that you can query the exposed metrics. Alternatively, you can access this port from the web browser on your physical system.

## 3.3. Set up the monitoring server

Add a new server, called `infra020` to the VM environment and assign IP-address 172.16.0.20. Install the `prometheus` role from the Prometheus Ansible collection.

### 3.3.1. Scraping metrics from other VMs

Set the variable `prometheus_scrape_configs` to specify how Prometheus can access the metrics. This variable should contain a list of dictionaries, where each dictionary specifies a "job", i.e. a set of similar metrics to be scraped from one or more targets. The following example shows how to scrape the Node Exporter on some HOST. You can specify an IP address or (if you also implement section 3.3.1.) a host name/FQDN.

```yaml
prometheus_scrape_configs:
  - job_name: 'node_exporter'
    metrics_path: '/metrics'
    static_configs:
      - targets:
          - 'HOST:9100'
```

Adapt the example to your needs, ensure all VMs in the environment are included, log in to the Prometheus dashboard and check that you receive metrics from all of them.

### 3.3.1. Using our own DNS server - Ansible as an orchestration tool

If your Prometheus server has to access all monitored VMs through their IP-address, the metrics they emit will become harder to interpret. We have set up a DNS server, so let's make use of it. The idea is to write an Ansible playbook that configures all VMs in our environment to use our DNS server.

Remember that on EL, this is done by editing the `/etc/resolv.conf` file. Use the `lineinfile` module to modify the present `nameserver`'s IP address to our own DNS server.

Write a new playbook, e.g. named `set-dns.yml` that runs this task on all VMs in the internal network and execute it. Check that the DNS server is now used by all VMs and that you can ping between VMs using their host names.

The reason that we created a new playbook for this single task is that after rebooting the VMs, the `/etc/resolv.conf` file will be overwritten again. By creating a separate playbook, we can run it whenever we need to ensure that the DNS server is used. This is an example of using Ansible as an *orchestration tool*. Orchestration is the process of automating a workflow or process, on machines that are already configured, and, possibly, in production.

If we want to use the host names in the Prometheus configuration, we need to make sure that the configuration change is applied *before* we set up Prometheus. We can do this by also copying this task to the `pre_tasks` section of the part of the `site.yml` playbook where you set up `infra020`. This section will be run before the role is applied.

From now on, in any Prometheus configuration setting, you can specify any host with their FQDN (e.g. `dmz010.infra.lan`, `infra003.infra.lan`) instead of their IP address. You can change the `prometheus_scrape_configs` variable accordingly.

## 3.4. Create a Dashboard with Grafana

The Prometheus web UI allows you to enter queries to visualize specific metrics. However, this is quite cumbersome, as it only shows what you ask for. What you probably want is a dashboard that shows essential information about the systems being monitored. Prometheus recommends to use Grafana for this purpose.

Install the [Ansible collection for Grafana](https://galaxy.ansible.com/ui/repo/published/grafana/grafana/) and the included `grafana`  role on your monitoring server. Set up Prometheus as a data source. In the web interface, create a Dashboard that shows at least some metrics gathered from Prometheus.

If an existing Grafana Dashboard can be reused for your setup, this can be automated through one of the role variables. If not, it's okay if the dashboard was created manually and cannot be automatically reproduced after a `vagrant destroy; vagrant up`. In that case, it's important to document the process thoroughly in your lab report.
