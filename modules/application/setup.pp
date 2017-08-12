host { 'repository': 
  ip => '10.24.45.127', 
} 
package { 'nginx':
    ensure => installed}

service { 'nginx':
    ensure => running,
    require => [
        Package['nginx'],
    ],
}
