export JAVA_HOME=/Library/Java/JavaVirtualMachines/liberica-jdk-21-full.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
removezulu() {
    unset JAVA_HOME
    unset PATH
}