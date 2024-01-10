<hr style="width:100%;text-align:left;margin-left:0">

<b>DEPRRECATED</b> This page is not maintained, but is kept for archival
purposes. GPU configuration is fully automatized in the Ansible-scripts
for host configuration

<hr style="width:100%;text-align:left;margin-left:0">


''' \*\* DO NOT USE THIS - ONLY FOR REFERENCE - ALREADY AUTOMATED IN
HOST SETUP SCRIPTS \*\* '''

This guide is aimed mainly for GPU without vGPU-support, as a
alternative approach to enable GPU computing inside a virtual machine.
It is tested on Dell Precision 7920 Rack with an Intel CPU, and based on
[this
guide](https://mathiashueber.com/pci-passthrough-ubuntu-2004-virtual-machine/).
This means, if the machine does not have an Intel CPU, it might be
better to follow the original guide directly.

Enable virtualization

1.  Go to BIOS
2.  Enable virtualzation
3.  If applicable, enable PCIe virtualization passthrough

Install required packages

Use the following command:

    sudo apt install qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf

Setting up the PCI passthrough

<span id="identify-bus-ids-and-gpu-ids"></span>

## Identify bus IDs and GPU IDs

1.  Run lspci -nnv and look for the GPU.
2.  Note **ALL** of the bus channels and ID's (including Serial, USB,
    and audio). See image below.

[lspci-list](/File:Lspci.png "wikilink")

<span id="edit-grub"></span>

## Edit GRUB

1.  sudo nano /etc/default/grub
2.  Edit or addGRUB_CMDLINE_LINUX_DEFAULT so it includes the option
    and all of the GPU IDs from the previous step:
        GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on vfio-pci.ids=<id1>,<id2>,<id...>"
    For example:
        GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on vfio-pci.ids=10de:1eb0,10de:10f8,10de:1ad8,10de:1ad9"
3.  sudo update-grub
4.  Reboot the machine
5.  Verify settings after reboot with dmesg | grep IOMMU

<span id="apply-vfio-pci-driver-by-pci-bus-id"></span>

## Apply VFIO-pci driver by PCI bus id

1.  sudo nano /etc/initramfs-tools/scripts/init-top/vfio.sh
2.  Paste the following lines and change the bus id placeholders, for
    example: 65:00.0 65:00.1 65:00.2 65:00.3.

<!-- end list -->

    #!/bin/sh

    PREREQ=""

    prereqs()
    {
        echo "$PREREQ"
    }

    case $1 in
    prereqs)
        prereqs
        exit 0
        ;;
    esac

    for dev in <bus id>
    do
        echo "vfio-pci" > /sys/bus/pci/devices/$dev/driver_override
        echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
    done

    exit 0

    3. sudo chmod +x /etc/initramfs-tools/scripts/init-top/vfio.sh

    4. sudo nano /etc/initramfs-tools/modules

<span>5. </span>Add the following line:

    options kvm ignore_msrs=1

    6. sudo update-initramfs -u -k all

<span id="verify-installation"></span>

## Verify installation

Run **lspci -nnv** and find the GPU. Ensure that **Kernel driver
<span>in</span> <span>use</span>: vfio-pci** 

<span id="start-gpu-vm-in-cloudstack"></span>

## Start GPU VM <span>in</span> CloudStack

1.  Make sure the VM <span>is</span> turned off
2.  Edit the VM<span>'s</span> settings <span>and</span> add a
    <span>new</span> entry **extraconfig-<span>1</span>** 
3.  Paste the following lines below <span>and</span> change the
    <span>bus</span> placeholder, <span>for</span> example
    **<span>bus</span>='<span>0</span>x65**'

<!-- end list -->

    <devices>
    <hostdev mode="subsystem" type="pci" managed="yes">
    <driver name="vfio"/>
    <source>
    <address domain="0x0000" bus="0x65" slot="0x00" function="0x0"/>
    </source>
    <alias name="nvidia0"/>
    <address type="pci" domain="0x0000" bus="0x00" slot="0x00" function="0x0"/>
    </hostdev>
    </devices>


If more cards are <span>to</span> be passed through <span>to</span>
<span>a</span> single machine, see [this
guide](https://lab.piszki.pl/cloudstack-kvm-and-running-vm-with-vgpu/).
Once finished, <span>the</span> settings panel should look like this:

[<File:Cloudstack-xml.png>](/File:Cloudstack-xml.png "wikilink")<span></span>

<span>4.</span> Start <span>the</span> VM

<span></span>

<span id="troubleshooting"></span>

## <span>Troubleshooting</span>

<span id="vfio-pci-driver-not-in-use"></span>

### <span>**vfio-pci** driver not in use</span>

Some devices <span>do</span> <span>not</span> automatically use
<span>the</span> <span>new</span> **vfio-pci**, so <span>it</span> can
be force bound <span>using</span> <span>a</span> bash script.

<span>1.</span> Make note <span>of</span> which driver <span>it</span>
is <span>using</span> instead <span>of</span> **vfio-pci**, such
<span>as</span> **nvidia-gpu**.

<span>2.</span> Create <span>a</span> bash script somewhere
<span>and</span> paste <span>the</span> <span>lines</span> below. Make
sure <span>to</span> swap <span>the</span> placeholder <span>with</span>
<span>the</span> bus id <span>of</span> <span>the</span> device
<span>with</span> <span>the</span> wrong driver.

    #!/bin/sh

    PCI_HID="0000:YOUR-BUS-ID-HERE"

    echo -n "$PCI_HID" > /sys/bus/pci/drivers//unbind

    echo -n "$PCI_HID" > /sys/bus/pci/drivers/vfio-pci/bind


If <span>it</span> is more than <span>one</span> device,
<span>lines</span> <span>2</span><span>-4</span> can be copied
<span>and</span> placed underneath.

<span>3.</span> **sudo nano
/etc/systemd/<span>system</span>/bind-gpu-drivers.service**

<span>4.</span> Paste <span>the</span> following <span>lines and</span>
change <span>the</span> script location placeholder:

    [Unit]
    Description=Bind GPU drivers so CloudStack can use them
    After=network-online.target

    [Service]
    ExecStart=your script location

    [Install]
    WantedBy=multi-user.target

5\. sudo systemctl enable bind-gpu-drivers.service && sudo systemctl
start bind-gpu-drivers.service